process PDBESIFTS_SEGMENTS {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE'
        : 'quay.io/biocontainers/YOUR-TOOL-HERE'}"

    input:
    tuple val(meta), path(cif), path(db)

    output:
    // Entries without mappable polypeptide chains produce no CSVs
    tuple val(meta), path("${prefix}/*_seg.csv.gz")  , emit: seg  , optional: true
    tuple val(meta), path("${prefix}/*_res.csv.gz")  , emit: res  , optional: true
    tuple val(meta), path("${prefix}/*_delta.csv.gz"), emit: delta, optional: true
    tuple val("${task.process}"), val('pdbe_sifts'), eval("python3 -c \"from importlib.metadata import version; print(version('pdbe_sifts'))\""), topic: versions, emit: versions_pdbesifts

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def db_arg = db ? "-d ${db}" : ''
    """
    pdbe_sifts \\
        segments \\
        -i ${cif} \\
        -o ${prefix} \\
        ${db_arg} \\
        ${args}
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    echo "" | gzip > ${prefix}/${prefix}_seg.csv.gz
    echo "" | gzip > ${prefix}/${prefix}_res.csv.gz
    echo "" | gzip > ${prefix}/${prefix}_delta.csv.gz
    """
}
