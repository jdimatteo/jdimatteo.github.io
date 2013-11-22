SELECT cell_type, chromosome, bin, count_fraction, percentile_in_cell_type 
FROM normalized_bins 
WHERE counter_version = 203 AND chromosome = 'chr1'
INTO OUTFILE '/Users/jdimatteo/DanaFarber/jdimatteo.github.io/data/normalized_bins_chr1.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
