rule ref_gc_wiggle:
    input:
        ref_fasta = config['ref_genome'] + ".fasta"
    output:
        wig_file = config['ref_genome'] + ".wig.gz"
    wildcard_constraints:
        sample="[^/]+"
    benchmark: "benchmarks/sqnz.ref_gc_wiggle.txt"
    log:
        stdout = "logs/sqnz.ref_gc_wiggle.out",
        stderr = "logs/sqnz.ref_gc_wiggle.err"
    threads: 1
    resources:
        tasks=2,
        mem_mb=10000,
        mpi="srun",
        runtime=2880,
        tasks_per_node=1
    container: "docker://sequenza/sequenza:latest"
    shell:
        """
        sequenza-utils gc_wiggle -w 50 --fasta {input.ref_fasta} -o {output.wig_file}
        1> {log.stdout} 2> {log.stderr}
        """

rule bam2seqz:
    input:
        normal_bam=lambda wildcards: config["samples"][wildcards.sample]["normal_bam"],
        tumor_bam =lambda wildcards: config["samples"][wildcards.sample]["tumor_bam"],
        ref_fasta =config['ref_genome'] + ".fasta",
        wig_file  =config['ref_genome'] + ".wig.gz",
    output:
        seqz_fn = "analysis/{sample}/seqz/{sample}.seqz.gz"
    wildcard_constraints:
        sample="[^/]+"
    benchmark: "benchmarks/sqnz.bam2seqz.{sample}.txt"
    log:
        stdout = "logs/sqnz.bam2seqz.{sample}.out",
        stderr = "logs/sqnz.bam2seqz.{sample}.err"
    threads: 1
    resources:
        tasks=2,
        mem_mb=10000,
        mpi="srun",
        runtime=2880,
        tasks_per_node=1
    container: "docker://sequenza/sequenza:latest"
    shell:
        "sequenza-utils bam2seqz "
        "-n {input.normal_bam} "
        "-t {input.tumor_bam} "
        "--fasta {input.ref_fasta} "
        "-gc {input.wig_file} "
        "-o {output.seqz_fn} "
        "1> {log.stdout} 2> {log.stderr}"

rule seqz_binning:
    input:
        seqz_fn = "analysis/{sample}/seqz/{sample}.seqz.gz"
    output:
        small_seqz_fn = "analysis/{sample}/seqz/{sample}.small.seqz.gz"
    wildcard_constraints:
        sample="[^/]+"
    benchmark: "benchmarks/sqnz.binning.{sample}.txt"
    log:
        stdout = "logs/sqnz.binning.{sample}.out",
        stderr = "logs/sqnz.binning.{sample}.err"
    threads: 1
    resources:
        tasks=2,
        mem_mb=10000,
        mpi="srun",
        runtime=2880,
        tasks_per_node=1
    container: "docker://sequenza/sequenza:latest"
    shell:
        "sequenza-utils seqz_binning "
        "--seqz {input.seqz_fn} "
        "-w 50 "
        "-o {output.small_seqz_fn} "
        "1> {log.stdout} 2> {log.stderr}"

rule run_sequenza:
    input:
        small_seqz_fn = "analysis/{sample}/seqz/{sample}.small.seqz.gz"
    output:
        segment_fn = "analysis/{sample}/output/{sample}_segments.txt",
        chr_depth  = "analysis/{sample}/output/{sample}_chromosome_depths.pdf"
    wildcard_constraints:
        sample="[^/]+"
    benchmark: "benchmarks/sqnz.run.{sample}.txt"
    log:
        stdout = "logs/sqnz.run.{sample}.out",
        stderr = "logs/sqnz.run.{sample}.err"
    threads: 1
    params:
        sample_id = lambda wildcards: wildcards.sample
    resources:
        tasks=2,
        mem_mb=10000,
        mpi="srun",
        runtime=2880,
        tasks_per_node=1
    container: "docker://sequenza/sequenza:latest"
    shell:
        "mkdir -p analysis/{wildcards.sample}/output/ && "
        "Rscript  /data/SJ/pipeline/sequenza_pipeline/bin/run_sequenza.R "
        "-i {input.small_seqz_fn} "
        "-o analysis/{wildcards.sample}/output/ "
        "-n {params.sample_id} "
        "1> {log.stdout} 2> {log.stderr}"
