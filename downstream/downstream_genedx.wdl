workflow downstream {
    String source_path
    String case

    call getInputFiles {
        input: src=source_path
    }
    
    scatter (f in getInputFiles.out) {
        call recompressWithBZip {
             input: in = f, name = sub(f, ".*/", "")
        }
        call tabix {
             input: in = recompressWithBZip.out
        }
        File recompressed = tabix.out
    }

    call mergeVCF {
        input: vcfs = recompressed, case = case
    }

    call deNovoCaller {
        input: case = mergeVCF.out, fam = source_path + "/" + case + ".fam"
    }
    call annotateVCF    { input: in=deNovoCaller.out }
    call loadIntoAnfisa { input: in=annotateVCF.out }
}

task getInputFiles {
    String src
    command {}
    output { Array[File] out = glob(src + "/*vcf*.gz") }
}

task recompressWithBZip {
    File in
    String name

    command {
       cat ${in} > ${name}
       echo recompressed >> ${name} 
    }
#    command {
#        zcat ${in} | bgzip > ${name}
#    }
    output {
        File out = "${name}"
    }
}

task tabix {
    File in
#    command {
#       tabix ${in}
#    }
    command {
        echo tabix >> ${in}
    }
    output {
        File out="${in}"
    }
}

task mergeVCF {
    String case
    Array[File] vcfs

    command {
        cat ${sep=" " vcfs} > ${case}.vcf.gz
        echo merged >> ${case}.vcf.gz
    }
#    command {
#        bcftools merge -o ${case}.vcf.gz -0 -O z --threads 4 ${sep=" " vcfs}
#    }    
    output {
        File out = "${case}.vcf.gz"
    }
}

task deNovoCaller {
    File case
    File fam

    command {
        cat ${case} >> new_calls.tsv
        cat ${fam}  >> new_calls.tsv
    }

#    command {
#        python3 -m variant_caller --vcf ${case} -f ${fam} --dnlib /path/to/models/denovo/idxlib/ --results path/to/{}.hg19.bam --callers de-novo-b --apply
#    }
    output {
        File out = "new_calls.tsv"
    }
}

task annotateVCF {
     File in
    
     command {
         cat ${in} > annotated.vcf.gz
         echo annotated >> annotated.vcf.gz
     }

     output {
         File out="annotated.vcf.gz"
     }
}

task loadIntoAnfisa {
     File in
    
     command {
         echo Loaded into anfisa!
     }
}
