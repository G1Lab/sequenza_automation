library(sequenza)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) %% 2 != 0) {
	    stop("Usage: Rscript run_sequenza.R -i input_file -n sample_name -o output_dir")
}

args_list <- list()
for (i in seq(1, length(args), by = 2)) {
	    key <- args[i]
    value <- args[i + 1]
        
        # 키에서 '-' 제거
        key <- sub("^-+", "", key)
        
        # 리스트에 추가
        args_list[[key]] <- value
}

required_args <- c("i", "n", "o")
missing <- setdiff(required_args, names(args_list))

if (length(missing) > 0) {
	    stop(paste("Missing required arguments:", paste(missing, collapse = ", ")))
}

input_file <- args_list[["i"]]
sample_name <- args_list[["n"]]
output_dir <- args_list[["o"]]

options(mc.cores = 1)

# 분석 실행
extracted <- sequenza.extract(file = input_file)
CP <- sequenza.fit(extracted)

sequenza.results(
    sequenza.extract = extracted,
    cp.table = CP,
    sample.id = sample_name,
    out.dir = output_dir
)


