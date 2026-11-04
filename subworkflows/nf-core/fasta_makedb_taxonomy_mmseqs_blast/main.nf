// Copyright (c) the nf-core community under an open-source MIT license.
// See https://github.com/nf-core/modules for full license, file patching instructions and upstream contributing.

include { MMSEQS_CREATEDB    } from '../../../modules/nf-core/mmseqs/createdb/main'
include { MMSEQS_CREATETAXDB } from '../../../modules/nf-core/mmseqs/createtaxdb/main'
include { MMSEQS_CREATEINDEX } from '../../../modules/nf-core/mmseqs/createindex/main'
include { BLAST_MAKEBLASTDB  } from '../../../modules/nf-core/blast/makeblastdb/main'

workflow FASTA_MAKEDB_TAXONOMY_MMSEQS_BLAST {

    take:
    ch_fasta_taxmap // channel: [ val(meta), path(fasta), path(tax_mapping) ]
    ch_taxdump      // channel: [ val(meta2), path(taxdump_dir) ]; only used when val_tool is 'mmseqs'
    val_tool        // string: 'mmseqs' or 'blast'

    main:
    ch_db = channel.empty()

    if (val_tool == 'mmseqs') {
        MMSEQS_CREATEDB(
            ch_fasta_taxmap.map { meta, fasta, _tax_mapping -> [ meta, fasta ] }
        )

        // createdb outputs arrive in completion order, so re-pair each database with its own mapping
        ch_createtaxdb_input = MMSEQS_CREATEDB.out.db
            .join(ch_fasta_taxmap.map { meta, _fasta, tax_mapping -> [ meta, tax_mapping ] }, failOnMismatch: true)
            .multiMap { meta, db, tax_mapping ->
                db:          [ meta, db ]
                tax_mapping: [ meta, tax_mapping ]
            }

        MMSEQS_CREATETAXDB(
            ch_createtaxdb_input.db,
            ch_taxdump.first(),
            ch_createtaxdb_input.tax_mapping
        )

        MMSEQS_CREATEINDEX(
            MMSEQS_CREATETAXDB.out.db_with_taxonomy
        )

        ch_db = MMSEQS_CREATEINDEX.out.db_indexed
    }
    else if (val_tool == 'blast') {
        ch_makeblastdb_input = ch_fasta_taxmap
            .multiMap { meta, fasta, tax_mapping ->
                fasta:       [ meta, fasta ]
                tax_mapping: tax_mapping
            }

        BLAST_MAKEBLASTDB(
            ch_makeblastdb_input.fasta,
            ch_makeblastdb_input.tax_mapping
        )

        ch_db = BLAST_MAKEBLASTDB.out.db
    }
    else {
        error("Unsupported val_tool '${val_tool}' for FASTA_MAKEDB_TAXONOMY_MMSEQS_BLAST: expected 'mmseqs' or 'blast'")
    }

    emit:
    db = ch_db // channel: [ val(meta), path(db_dir) ]
}
