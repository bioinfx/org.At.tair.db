library(RSQLite)
library(AnnotationForge)
options(stringsAsFactors = F)

# GENE-GO注释的数据框
# ATH_GO_TERM.txt were create 
# by `cat ATH_GO_GOSLIM.txt | cut -f 1,6,8,10 > ATH_GO_TERM.txt`
go_df <- read.table("./ATH_GO_TERM.txt",
                      sep="\t", header = FALSE,
                      as.is = TRUE)

go_df$V3 <- ifelse(go_df$V3 == "C", "CC",
                     ifelse(go_df$V3 == "P", "BP",
                            ifelse(go_df$V3 == "F", "MF", "")))

# http://www.geneontology.org/page/guide-go-evidence-codes
# remove the following code
# as the IEA is trustbly according to 
# Pathway enrichment analysis and visualization of omics data using g:Profiler, GSEA, Cytoscape and EnrichmentMap
# go_df <- go_df[! go_df$V4 %in% "IEA",]

colnames(go_df) <- c("GID","GO","ONTOLOGY","EVIDENCE")

# GENE-PUB的数据框
pub_df <- read.table("./Locus_Published_20180330.txt.gz",
                     sep="\t",
                     header = TRUE)

## 只选择AT开头的基因
pub_df <- pub_df[grepl(pattern = "^AT\\d", pub_df$name),]
pub_df <- cbind(GID=do.call(rbind,strsplit(pub_df$name, split = "\\."))[,1],
                pub_df)

# convert NA to blank
pub_df$pubmed_id <- ifelse(is.na(pub_df$pubmed_id), "",pub_df$pubmed_id)

colnames(pub_df) <- c("GID","GENEID","REFID",
                      "PMID","PUBYEAR")

# GENE-SYMBOL的注释数据库
symbol_df <- read.table("./gene_aliases_20180330.txt.gz",
                        sep = "\t",
                        header = TRUE)
symbol_df <- symbol_df[grepl(pattern = "^AT\\d", symbol_df$name),]
colnames(symbol_df) <- c("GID","SYMBOL","SYMBOL_NAME")

# GENE-FUNCTION
func_df <- read.table("./Araport11_functional_descriptions_20180330.txt.gz",
                      sep = "\t",
                      header=TRUE)
func_df <- func_df[grepl(pattern = "^AT\\d", func_df$name),]
func_df <- cbind(GID=do.call(rbind,strsplit(func_df$name, split = "\\."))[,1],
                  func_df)
colnames(func_df) <- c("GID","TXID","GENE_MODEL_TYPE",
                       "SHORT_DESCRIPTION",
                       "CURATED_DESCRIPTION",
                       "DESCRIPTION")
func_df$SHORT_DESCRIPTION <- ifelse(nchar(func_df$SHORT_DESCRIPTION) == 0, 
                                    NA, func_df$SHORT_DESCRIPTION)

func_df$DESCRIPTION <- gsub("\\(source:Araport11\\)","", func_df$DESCRIPTION)

## remove duplicated
go_df <- go_df[!duplicated(go_df), ]
go_df <- go_df[,c(1,2,4)]
pub_df <- pub_df[!duplicated(pub_df),]
symbol_df <- symbol_df[!duplicated(symbol_df),]
func_df <- func_df[!duplicated(func_df),]


# no duplicated row
# all GID should be same type, be aware of factor
file_path <- file.path( getwd())
makeOrgPackage(go=go_df,
               pub_info = pub_df,
               symbol_info = symbol_df,
               function_info = func_df,
               version = "0.1",
               maintainer = "xuzhougeng <xuzhougeng@163.com>",
               author="xuzhogueng <xuzhougeng@163.com>",
               outputDir = file_path,
               tax_id = "3702",
               genus = "At",
               species = "tair10",
               goTable = "go"
  
)


install.packages("./org.Atair10.eg.db", repos = NULL,
                 type = "source")