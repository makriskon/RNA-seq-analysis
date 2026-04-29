#!/bin/sh
#SBATCH --job-name=fastp
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --nodes=1
##SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=16
##SBATCH --time=3:00:00
#SBATCH --mem=200G 
#SBATCH --partition=cpu_p
#SBATCH -q cpu_normal

#!/bin/bash

# Define paths
INPUT_DIR="/ictstr01/home/ido/konstantinos.makris/Susi_mol_met/raw_samples"
OUTPUT_DIR="/ictstr01/home/ido/konstantinos.makris/Susi_mol_met/trimmed_samples"

mkdir -p ${OUTPUT_DIR}

for R1 in ${INPUT_DIR}/*_1.fq.gz; do

    # Check R1 exists
    [ -f "$R1" ] || { echo "No .fq.gz files found in ${INPUT_DIR}"; exit 1; }

    # Derive R2
    R2=${R1/_1.fq.gz/_2.fq.gz}

    # Check R2 exists
    if [ ! -f "$R2" ]; then
        echo "WARNING: R2 not found for $R1, skipping..."
        continue
    fi

    # Extract sample name
    SAMPLE=$(basename ${R1} _1.fq.gz)
    echo "========================================="
    echo "Processing sample: ${SAMPLE}"
    echo "========================================="

    # --- STEP 1: UNZIP ---
    echo "[1/2] Unzipping ${SAMPLE}..."
    gunzip -k ${R1}   # -k keeps the original .gz file
    gunzip -k ${R2}

    # Define unzipped file paths
    R1_FQ=${INPUT_DIR}/${SAMPLE}_1.fq
    R2_FQ=${INPUT_DIR}/${SAMPLE}_2.fq

    # --- STEP 2: FASTP ---
    echo "[2/2] Running fastp on ${SAMPLE}..."
    fastp \
        -i ${R1_FQ} \
        -I ${R2_FQ} \
        -o ${OUTPUT_DIR}/${SAMPLE}_1_fastp.fq \
        -O ${OUTPUT_DIR}/${SAMPLE}_2_fastp.fq \
        -h ${OUTPUT_DIR}/${SAMPLE}.fastp.html \
        -j ${OUTPUT_DIR}/${SAMPLE}.fastp.json \
        --thread 8 \
        --detect_adapter_for_pe \
        --qualified_quality_phred 20 \
        --length_required 36 \
        --correction \
        -w 8

    # --- Optionally remove unzipped raw files to save space ---
     rm ${R1_FQ} ${R2_FQ}

    echo "Done: ${SAMPLE}"
 done

 echo "All samples trimmed successfully."

#---------------------Loop over the trimmed samples for performing alignment over mouse genome mm39--------
GENOME_DIR="/home/ido/konstantinos.makris/mouse_genome_mm39"
OUTPUT_DIR="/ictstr01/home/ido/konstantinos.makris/Susi_mol_met/mm39_aligned_samples"
INPUT_DIR="/ictstr01/home/ido/konstantinos.makris/Susi_mol_met/trimmed_samples"

mkdir -p ${OUTPUT_DIR}

for R1 in ${INPUT_DIR}/*_1.fq.gz; do

    # Check file exists
    [ -f "$R1" ] || { echo "No files found"; exit 1; }

    # Derive R2
    R2=${R1/_1.fq.gz/_2.fq.gz}

    # Check R2 exists
    if [ ! -f "$R2" ]; then
        echo "WARNING: R2 not found for $R1, skipping..."
        continue
    fi

    # Extract sample name
    SAMPLE=$(basename ${R1} _1.fq.gz)

    echo "Processing: ${SAMPLE}"

    STAR --genomeDir ${GENOME_DIR} \
         --readFilesIn ${R1} ${R2} \
         --readFilesCommand zcat \          # ← critical for .gz files
         --outFileNamePrefix ${OUTPUT_DIR}/${SAMPLE}_ \
         --outSAMtype BAM SortedByCoordinate \
         --outSAMattributes NH HI AS NM \
         --runThreadN 8

    # Index the output BAM
    samtools index ${OUTPUT_DIR}/${SAMPLE}_Aligned.sortedByCoord.out.bam

    echo "Done: ${SAMPLE}"
done

echo "All samples processed."

#----This function was used to run solely samples------------------------------------------------------
#STAR --genomeDir "/home/ido/konstantinos.makris/mouse_genome_mm39" \
#         --readFilesIn "A9_MKRN250063019-1A_235LJ3LT4_L2_1.fq" "A9_MKRN250063019-1A_235LJ3LT4_L2_2.fq" \
#         --outFileNamePrefix "/ictstr01/home/ido/konstantinos.makris/Susi_mol_met/mm39_aligned_samples/A9_MKRN250063019-1A_235LJ3LT4_L2_" \
#         --outSAMtype BAM SortedByCoordinate
#------------------------------------------------------------------------------------------------------

#----------------------------- Perform Feature Count table---------------------------------------------
featureCounts -p --countReadPairs -a /home/ido/konstantinos.makris/genome/mm39_index/Mus_musculus.GRCm39.112.gtf -t exon -g gene_id -o /home/ido/konstantinos.makris/STAR/*.featureCounts.txt /home/ido/konstantinos.makris/STAR/*.out.bam
