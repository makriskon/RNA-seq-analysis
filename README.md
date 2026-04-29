Bulk RNA-seq analysis

Pre-processing steps-quality control/trimming/alignment/featurecount table 
•	Download the mouse/human genome from NCBI or ENSEMBL in order to index the genome and use STAR to index-Keep all the files at the same folder in order to use STAR mapper.
•	Perform MultiQC report (Ewels et al. 2016)-normally is given by the Genomic Facility about the quality of the sequencing (adaptors/duplicates etc.). It can be also Falco, which is an efficiency-optimized rewrite of FastQC, to create a report of sequence quality or Cutadapt (Marcel 2011) to improve the quality of sequences via trimming and filtering.
•	Then since you have the fastq files, trim them from adaptors and low-quality sequences (artifacts of the sequencer), where you will have only the duplicates of the RNA-seq produced by the libraries
•	Trimmed sequenced will be aligned towards the indexed mouse/human genome by using STAR mapper. Be careful to use the same version of STAR mapper to align the samples and index the genome.
•	After alignment, it is necessary to perform FeatureCounts, where you will sum all the counts from the different samples, having a final table to work.
•	Mapping results can be inspected also using the IGV by using the aligned BAM files and checking the alignment or perturbation by the deletion of a specific exon/intron if you have a specific modified model.

Differential Expression Analysis
•	Import the data in R studio and start the analysis using R or Python.
•	Pre-filter the noisy genes by summing the counts of the different replicates. A good filtering to remove noisy genes is to have on average 50-100 counts per replicate for a gene. Or at least 400-500 counts for 4-5 replicates. By filtering the noisy genes, you avoid focusing on the noisy.
•	Then define your DESEq2 linear and perform DESEq2 analysis, where you normalize your libraries. Normalization is a mandatory step for removing biases in the sequencing library size by the library preparation due to amplification steps.
•	After pre-filtering and normalization, you can perform PCA and hierarchical clustering to see if all of your replicates per condition are separated or there are abnormal distances between your samples.
•	In case of outliers by the PCA and/or clustering, it is advised to be removed any potential outlier.
•	In case of facing problems and your experiment comes from pull of different batches or experimental rounds, it is suggested to perform SVA batch effect correction. The most widely used in ComBat (from the sva package). SVA tries to capture unwanted variation (batch/technical effects) while preserving true biological information. After this step, you need to perform again PCA/clustering to see the removal of the technical effects.

PCA plot:
It shows the samples in the 2D plane spanned by their first two principal components. Each replicate is plotted as an individual data point. This type of plot is useful for visualizing the overall effect of experimental covariates and batch effects.
Heatmap of the sample-to-sample distance matrix (with clustering) based on the normalized counts:

The heatmap gives an overview of similarities and dissimilarities between samples: the color represents the distance between the samples. Dark blue means shorter distance, i.e. closer samples given the normalized counts.

Dispersion estimates: gene-wise estimates (black), the fitted values (red), and the final maximum a posteriori estimates used in testing (blue):
This dispersion plot is typical, with the final estimates shrunk from the gene-wise estimates towards the fitted estimates. Some gene-wise estimates are flagged as outliers and not shrunk towards the fitted value. The amount of shrinkage can be more or less than seen here, depending on the sample size, the number of coefficients, the row mean and the variability of the gene-wise estimates.

Histogram of p-values for the genes in the comparison between the 2 levels of the 1st factor

MA plot:
This displays the global view of the relationship between the expression change of conditions (log ratios, M), the average expression strength of the genes (average mean, A), and the ability of the algorithm to detect differential gene expression (DEG). The genes that passed the significance threshold (adjusted p-value < 0.1) are colored in blue.

•	By performing DESeq2, you will compare the conditions, and you will have an output where it will be summarized with the: Gene identifiers, Mean normalized counts, averaged over all samples from both conditions, Fold change in log2 (logarithm base 2) [The log2 fold changes are based on the primary factor level 1 vs factor level 2, hence the input order of factor levels is important. Here, DESeq2 computes fold changes of ‘treated’ samples against ‘untreated’ from the first factor ‘Treatment’, i.e. the values correspond to up- or downregulation of genes in treated samples.], Standard error estimate for the log2 fold change estimate, Wald statistic, p-value for the statistical significance of this change, and p-value adjusted for multiple testing with the Benjamini-Hochberg procedure, which controls false discovery rate after BH-FDR correction.
•	As a normal threshold of significance, it is suggested to be used the FDR <0.05 and log2FC > +1/1.5 (UP) & log2FC < -1/-1.5 (DOWN).
•	Annotation of the Gene identifiers can be performed using the R package biomaRt.
•	Further visualization of genes by visualizing in a Volcano plot to see the top DEGs and the proper shape. Additionally, we can perform in the significant one Reactome, KEGG analysis and visualize them as row Z-score normalized counts in the form of Heatmaps.
•	Lastly, in case we want to visualize them in boxplots it is suggested to use the log transformed or VST normalized counts and use the statistics coming from the Wald test by BH-FDR correction.
