process PDBESIFTS_SEQUENCEMATCH {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/00/00bfe5269a959dbc72993abaa314164cf1e720d56769ff438adcae89155eab8a/data'
        : 'community.wave.seqera.io/library/blast_mmseqs2_c-compiler_pip_pruned:f0136bed7613f457' }"

    input:
    tuple val(meta), path(input_file)
    tuple val(meta2), path(db)

    output:
    tuple val(meta), path("${prefix}/*/*.duckdb"), emit: duckdb
    tuple val(meta), path("${prefix}/*/*.tsv")   , emit: tsv
    tuple val("${task.process}"), val('pdbe_sifts'), eval("python3 -c \"from importlib.metadata import version; print(version('pdbe_sifts'))\""), topic: versions, emit: versions_pdbesifts

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    """
    pdbe_sifts \\
        sequence_match \\
        -i ${input_file} \\
        -o ${prefix} \\
        -d ${db} \\
        --threads ${task.cpus} \\
        ${args}
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    // Mirrors the tool's entry-name derivation: strip the first matching known suffix
    def entry = input_file.name.replaceFirst(/(?i)(\.cif\.gz|\.cif|\.fasta|\.fa|\.faa|\.txt)$/, '')
    """
    mkdir -p ${prefix}/mmseqs_${entry}
    touch ${prefix}/mmseqs_${entry}/hits.duckdb
    touch ${prefix}/mmseqs_${entry}/hits_${entry}.tsv
    """
}
