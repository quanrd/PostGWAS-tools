help_message = '
db_venn, v2020-03-13
This is a function call for venn analysis of filtered DB data.

Usage: Rscript postgwas-exe.r --dbvenn <function> --base <base files> --out <out folder> --fig <figure out folder>

Functions:
	venn        Venn analysis of rsids.
	summ        Generating summary table with annotations.

Global arguments:
	--base      <base files>
			    At least 2 Base BED file paths are mendatory.
			    For the venn function,if the base file number is over 4, then venn diagram is not generated.
	--out       <out folder>
			    Out folder path is mendatory. Default is "data" folder.

Required arguments:
	--fig       <figure out folder>
			    An optional argument for the "venn" function to save figure file.
			    If no figure out path is designated, no venn figure will generated.
	--uni_list  <default: FALSE>
				An optional argument for the "venn" function.
				To return the union SNP list.
	--sub_dir   <default: FALSE>
				An optional argument for the "summ" function.
				To get file paths grouped by the subfoler.
	--uni_save  <default: TRUE>
				An optional argument for the "summ" function.
				To save to union SNP list as a BED file.
	--ann_gwas  <GWAS annotation TSV file>
			    An optional argument for the "summ" function.
				Add GWAS annotations to the summary table 1.
	--ann_encd  <ENCODE annotation dist file>
			    An optional argument for the "summ" function.
				Add ENCODE annotations to the summary table 2.
	--ann_near  <Nearest gene annotation dist file>
			    An optional argument for the "summ" function.
				Add nearest gene annotations to the summary table 3.
	--ann_cds   <Gene CDS annotation dist file>
			    An optional argument for the "summ" function.
				Add gene CDS annotations to the summary table 3.
	--ann_gtex  <GTEx eQTL annotation TSV file>
			    An optional argument for the "summ" function.
				Add GTEx eQTL annotations to the summary table 4.
	--ann_lnc   <lncRNA annotation TSV file>
			    An optional argument for the "summ" function.
				Add lncRNA annotations to the summary table 5.
'

## Load global libraries ##
suppressMessages(library(dplyr))

## Functions Start ##
summ_ann = function(
	f_paths  = NULL,   # Input BED file paths
	sub_dir  = FALSE,  # Getting file paths only in the subfolder
	out      = 'data', # Out folder path
	uni_save = TRUE,   # Save the union SNP list as a BED format
	ann_gwas = NULL,   # Optional, add GWAS annotation TSV file path        -> CSV file 1
	ann_encd = NULL,   # Optional, add ENCODE Tfbs dist file path           -> CSV file 2
	ann_near = NULL,   # Optional, add nearest gene dist file path          -> CSV file 3
	ann_cds  = NULL,   # Optional, add gene CDS dist file path              -> CSV file 3
	ann_gtex = NULL,   # Optional, add GTEx significant eQTL TSV file path  -> CSV file 4
	ann_lnc  = NULL    # Optional, add lncRNA TSV file path                 -> CSV file 5
) {
	# Load function-specific library
	suppressMessages(library(biomaRt))

	# Prepare...
	paste0('\n** Run function: db_venn.r/summ... ') %>% cat
	ifelse(!dir.exists(out), dir.create(out),''); 'ready\n' %>% cat

	# If the base path is folder, get the file list
	dir_name = basename(f_paths)
	paths1 = list.files(f_paths,full.name=T)
	n = length(paths1)
	paste0(n,' Files/folders input.\n') %>% cat

	paths = NULL; paths_li = list(); dir_nm_li = list(); j = 0
	for(i in 1:n) {
		paths2  = list.files(paths1[i],full.name=T)
		if(length(paths2)==0) {
			paths = c(paths,paths1[i])
			paste0('  ',i,' ',paths1[i],'\n') %>% cat
		} else {
			if(sub_dir) {
				j = j+1
				dir_nm_li[[j]] = paths1[i] %>% basename
				paths_li[[j]]  = paths2
				paste0('  ',i,' sub_dir ',j,': ',length(paths2),' file(s) in the ',
					dir_nm_li[[j]],' folder\n') %>% cat
			} else {
				paths = c(paths,paths2)
				paste0('  ',i,' ',length(paths2),' files in the ',
					paths1[i] %>% basename,'\n') %>% cat
			}
		}
	}
	if(sub_dir) {
		paste0('Total ',length(paths_li),' sub-folder(s) is/are input\n') %>% cat
	}
	paste0('Total ',length(paths),' file(s) is/are input.\n') %>% cat

	# Run venn_bed function to get union table
	if(sub_dir =='TRUE') { sub_dir  = TRUE
	} else                 sub_dir  = FALSE
	if(uni_save=='TRUE') { uni_save = TRUE
	} else                 uni_save = FALSE
	if(sub_dir & uni_save) {
		paste0('\nOption sub_dir = TRUE, summary table are not going to be generated.\n') %>% cat
		for(k in 1:j) {
			union_df = venn_bed(paths_li[[k]],out,fig=NULL,uni_list=TRUE,debug=FALSE)
			if(is.null(union_df)) { nrow_union_df = 0
			} else                  nrow_union_df = unique(union_df)%>% nrow
			f_name1 = paste0(out,'/snp_union_',dir_name,'_',dir_nm_li[[k]],'_',
				nrow_union_df,'.bed')
			write.table(union_df[,c(2:4,1)] %>% unique,f_name1,
				col.names=F,row.names=F,quote=F,sep='\t')
			paste0('  ',k,' Write a BED file: ',f_name1,'\n') %>% cat
		}
		return('')
	} else if(length(paths)>0) {
		union_df = venn_bed(paths,out,fig=NULL,uni_list=TRUE)
	}
	paste0('** Back to function: db_venn.r/summ...\n') %>% cat
	paste0('  Returned union list dim\t= ') %>% cat; dim(union_df) %>% print
	union_summ = union_df[,c(-2,-3,-4)]

	# Write union BED file
	dir_name = dir_name[1] # debug 2020-03-17
	if(uni_save) {
		if(!is.null(dir_name)) {
			f_name1 = paste0(out,'/snp_union_',dir_name,'_',unique(union_df)%>%nrow,'.bed')
		} else f_name1 = paste0(out,'/snp_union_',unique(union_df)%>%nrow,'.bed')
		write.table(union_df[,c(2:4,1)] %>% unique,f_name1,col.names=F,row.names=F,quote=F,sep='\t')
		paste0('  Write a BED file: ',f_name1,'\n') %>% cat
	} else paste0('\n  [PASS] uni_save\t= ',uni_save,'\n') %>% cat

	# Generate GWAS summary
	if(!is.null(ann_gwas)) {
		## Read GWAS annotation TSV file
		paste0('\n  GWAS dim\t= ') %>% cat
		gwas = read.delim(ann_gwas,stringsAsFactors=F)
		dim(gwas) %>% print

		## Merge union data and GWAS annotation
		paste0('  Merge dim\t= ') %>% cat
		gwas_ann   = gwas[,1:8]
		gwas_merge = merge(gwas_ann,union_summ,by='rsid',all.x=T) %>% unique
		dim(gwas_merge) %>% print

		## Write a summary CSV file
		f_name2 = paste0(out,'/',dir_name,'_gwas.csv')
		write.csv(gwas_merge,f_name2,row.names=F)
		paste0('  Write a CSV file: ',f_name2,'\n') %>% cat
	} else paste0('\n  [PASS] GWAS summary.\n')

	# Generate ENCODE summary
	if(!is.null(ann_encd)) {
		## Read ENCODE Tfbs distance file
		paste0('\n  ENCODE dim\t= ') %>% cat
		enc = read.delim(ann_encd,header=F)
		dim(enc) %>% print

		## Merge union data and ENCODE annotation
		paste0('  Merge dim\t= ') %>% cat
		k = ncol(enc)
		which_row = which(enc[,k]==0)
		enc_      = enc[which_row,]
		tf_range  = paste0(enc_[,5],':',enc_[,6],'-',enc_[,7])
		enc_ann   = data.frame(
			rsid    = enc_[,4],
			tfbs    = enc_[,8],
			tfbs_rg = tf_range
		)
		enc_merge = merge(enc_ann,union_summ,by='rsid',all.x=T) %>% unique
		dim(enc_merge) %>% print

		## Write a summary CSV file
		f_name3 = paste0(out,'/',dir_name,'_encode.csv')
		write.csv(enc_merge,f_name3,row.names=F)
		paste0('  Write a CSV file: ',f_name3,'\n') %>% cat
	} else paste0('\n  [PASS] ENCODE summary.\n')

	# Generate nearest gene summary
	if(!is.null(ann_near)) {
		## Read nearest gene distance file
		paste0('\n  Nearest gene dim\t= ') %>% cat
		near = read.delim(ann_near,header=F)
		dim(near) %>% print

		## Extract data to prepare merge
		near_ann   = near[,c(4,8:9)]
		colnames(near_ann) = c('rsid','nearest','dist')

		# Search biomaRt for gene symbol and name
		paste0('  Search biomaRt... ') %>% cat
		genes = near_ann$nearest %>% unique
		paste0(length(genes),'.. ') %>% cat
		ensembl   = useMart("ensembl",dataset="hsapiens_gene_ensembl")
		gene_attr = c("ensembl_gene_id","hgnc_symbol","description")
		gene_ens  = getBM(
    		attributes = gene_attr,
    		filters = "ensembl_gene_id",
    		values = genes,
    		mart = ensembl
		) %>% unique

		# Parsing biomaRt gene name
		gene_name = lapply(gene_ens$description,function(desc) {
    		g_name = strsplit(desc,"\\ \\[") %>% unlist
    		return(g_name[1])
		}) %>% unlist
		gene_ens$name = gene_name
		paste0(length(gene_ens$ensembl_gene_id %>% unique),'.. ') %>% cat
		gene_ann = merge(near_ann,gene_ens[,c(1:2,4)],
    		by.x='nearest',by.y='ensembl_gene_id',all.x=T)
		dim(gene_ann) %>% print

		## Read CDS distance file
		if(!is.null(ann_cds)) {
			paste0('  CDS dim\t\t= ') %>% cat
			cds = read.delim(ann_cds,header=F)
			dim(cds) %>% print

			k = ncol(cds)
			which_row = which(cds[,k]==0)
			cds_      = cds[which_row,]
			cds_rg    = paste0(cds_[,5],':',cds_[,6],'-',cds_[,7])
			cds_enst  = lapply(cds_[,8], function(ensts) {
				enst = strsplit(ensts %>% as.character, "\\_")[[1]][1]
				return(enst)
			}) %>% unlist
			cds_ann   = data.frame(
				rsid     = cds_[,4] %>% as.character,
				cds_name = cds_[,8] %>% as.character,
				cds_enst = cds_enst %>% as.character,
				cds_rg   = cds_rg
			)

		## Merge union data, nearest gene data, and CDS data
			paste0('  Merge dim\t\t= ') %>% cat
			ann_li   = list(gene_ann,cds_ann,union_summ)
		} else {
			paste0('  Merge dim\t\t= ') %>% cat
			ann_li   = list(gene_ann,union_summ)
		}
		merge_allx = function(x,y) {
			merge(x,y,by='rsid',all.x=T)
		}
		near_merge = Reduce(merge_allx,ann_li) %>% unique
		dim(near_merge) %>% print

		## Write a summary CSV file
		f_name4 = paste0(out,'/',dir_name,'_nearest.csv')
		write.csv(near_merge,f_name4,row.names=F)
		paste0('  Write a CSV file: ',f_name4,'\n') %>% cat
	} else {
		if(!is.null(ann_cds)) {
			paste0('  [PASS] CDS have to be merged to nearest gene data.\n') %>% cat
		} else paste0('  [PASS] Nearest gene summary.\n') %>% cat
	}

	# Generate GTEx eQTL summary
	if(!is.null(ann_gtex)) {
		## Read GTEx eQTL annotation TSV file
		paste0('\n  GTEx dim\t= ') %>% cat
		gtex = read.delim(ann_gtex)
		dim(gtex) %>% print

		## Merge union data and the GTEx annotation
		paste0('  Merge dim\t= ') %>% cat
		gtex_ann   = gtex[,c(-7,-8)]
		gtex_merge = merge(gtex_ann,union_summ,by='rsid',all.x=T) %>% unique
		dim(gtex_merge) %>% print

		## Write a summary CSV file
		f_name5 = paste0(out,'/',dir_name,'_gtex.csv')
		write.csv(gtex_merge,f_name5,row.names=F)
		paste0('  Write a CSV file: ',f_name5,'\n') %>% cat
	} else paste0('\n  [PASS] GTEx summary.\n')

	# Generate lncRNA summary
	if(!is.null(ann_lnc)) {
		## Read lncRNA annotation TSV file
		paste0('\n  lncRNA dim\t= ') %>% cat
		lnc = read.delim(ann_lnc)
		dim(lnc) %>% print

		## Merge union data and the GTEx annotation
		paste0('  Merge dim\t= ') %>% cat
		lnc_ann   = lnc
		lnc_merge = merge(lnc_ann,union_summ,by.x='dbsnp',by.y='rsid',all.x=T) %>% unique
		dim(lnc_merge) %>% print

		## Write a summary CSV file
		f_name6 = paste0(out,'/',dir_name,'_lncRNA.csv')
		write.csv(lnc_merge,f_name6,row.names=F)
		paste0('  Write a CSV file: ',f_name6,'\n') %>% cat
	} else paste0('\n  [PASS] lncRNA summary.\n')
	'\n' %>% cat
}

venn_bed = function(
	f_paths  = NULL,   # Input BED file paths
	out      = 'data', # Out folder path
	fig      = NULL,   # Figure out folder path
	uni_list = FALSE,  # return the union SNP list as a BED format
	debug    = TRUE
) {
	# Function specific library
	suppressMessages(library(eulerr))
	suppressMessages(library(tools))
	
	# Prepare...
	if(debug) paste0('\n** Run function: db_venn.r/venn_bed...\n') %>% cat
	n         = length(f_paths)
	snp_li    = list()
	snpids_li = list()
	names     = NULL
	
	# Read BED files
	j = 0
	for(i in 1:n) {
		tb = try(read.delim(f_paths[i],header=F,stringsAsFactors=F))
		if('try-error' %in% class(tb)) {
			paste0('  [ERROR] ',f_paths[i],'\n') %>% cat
			next
		}
		colnames(tb)   = c('chr','start','end','rsid')
		j = j+1
		snp_li[[j]]    = tb
		snpids_li[[j]] = tb$rsid
		f_base         = basename(f_paths[i]) %>% file_path_sans_ext
		names          = c(names,f_base)
		if(n<10 & debug) {       paste0('  Read ',i,': ',f_base,'\n') %>% cat
		} else if(i==n & debug)  paste0('  Read ',n,' files\n') %>% cat
	}
	if(length(snp_li)==0) return(NULL)
	snp_df    = data.table::rbindlist(snp_li) %>% unique
	unionlist = Reduce(union,snpids_li)

	# Prepare for collapsing the list to one dataFrame list
	unionPr  = NULL
	subtitle = NULL
	for(i in 1:length(snpids_li)) {
		unionPr  = cbind(unionPr,snpids_li[[i]][match(unionlist,snpids_li[[i]])])
		subtitle = c(subtitle,paste0(names[i],'\n',length(snpids_li[[i]])))
	}
	rownames(unionPr) = unionlist

	# Generate binary table to match with ID list
	union = (unionPr != '')			# Transcform values to TRUE, if ID exists.
	union[is.na(union)] = FALSE		# Transform NA to FALSE value
	union = as.data.frame(union)	# Make 'union' to data.frame from
	colnames(union) = subtitle		# Names attach to venn diagram

	# Draw Venn plot
	title  = paste0(' Venn analysis of ',nrow(union),' SNPs')
	if(n %in% c(2,4) & !is.null(fig)) {
		fig_name1 = paste0(fig,'/venn_',n,'_',paste0(names,collapse=', '),'.png')
		png(fig_name1,width=10,height=10,units='in',res=100)
		limma::vennDiagram(
			union,
			main       = title,
			circle.col = rainbow(subtitle%>%length)
		)
		dev.off()
		paste0('\nFigure draw:\t\t',fig_name1,'\n') %>% cat
	} else if(n>4) {
		if(debug) message("\n[Message] Can't plot Venn diagram for more than 5 sets.")
	}

	# Draw Euler plot
	if(n == 3 & !is.null(fig)) {
		paste0('\n** Euler fitting... ') %>% cat
		vennCount = limma::vennCounts(union)
		fig_name2 = paste0(fig,'/euler_',n,'_',paste0(names,collapse=', '),'.png')
		png(fig_name2,width=10,height=10,units='in',res=100)
		venn_c   = unlist(vennCount[,4])
		venn_fit = euler(c(
			'A'     = venn_c[5] %>% as.numeric,
			'B'     = venn_c[3] %>% as.numeric,
			'C'     = venn_c[2] %>% as.numeric,
			'A&B'   = venn_c[7] %>% as.numeric,
			'A&C'   = venn_c[6] %>% as.numeric,
			'B&C'   = venn_c[4] %>% as.numeric,
			'A&B&C' = venn_c[8] %>% as.numeric
		))
		paste0('done.\n') %>% cat
		p = plot(
			venn_fit,
			quantities = T,
			labels     = colnames(vennCount)[1:3],
			edges      = list(col  = c('red','green','blue'),lwd=3),
			fills      = list(fill = c('red','green','blue'),alpha=.2),
			main       = title
		)
		print(p)
		dev.off()
		paste0('\nFigure draw:\t\t',fig_name2,'\n') %>% cat
	} else {
		if(debug) message("\n[Message] Can't plot Euler plot.")
	}
	if(debug) cat('\n')

	# Set the TSV file name
	if(n>3) {
		con_name = paste0(names[1],'-',names[n])
	} else con_name = paste0(names,collapse=', ')
	f_name1 = paste0(out,'/venn_',n,'_',con_name,'.tsv')

	# Save the venn result as a TSV file
	colnames(union) = names
	union_df  = cbind(union,rsid=rownames(union))
	union_out = merge(snp_df,union_df,by='rsid',all=T)
	if(!uni_list) {
		write.table(union_out,f_name1,row.name=F,quote=F,sep='\t')
		paste0('Write TSV file:\t\t',f_name1,'\n') %>% cat
	}

	# Extract core/union snp list
	if(n == 2 & !uni_list) {
		which_row = which(
			union_out[,5] == TRUE &
			union_out[,6] == TRUE
		)
	} else if(n == 3 & !uni_list) {
		which_row = which(
			union_out[,5] == TRUE &
			union_out[,6] == TRUE &
			union_out[,7] == TRUE
		)
	} else if(uni_list) {
		which_row = c(1:nrow(union_out)) # all union list
	} else {
		paste0('\n[Message] If you need a core rsid BED file,
	please input two or three files.') %>% message
		quit() # stop here
	}
	core_df = union_out[which_row, c(2:4,1)]

	# Write the core snp list as a BED file
	f_name2 = paste0(out,'/snp_core_',unique(core_df)%>%nrow,'.bed')
	if(!uni_list) {
		write.table(core_df,f_name2,row.names=F,col.names=F,quote=F,sep='\t')
		paste0('Write snp list as a BED file:\t',f_name2,'\n\n') %>% cat
		
	# Return union snp list for further annotationss
	} else return(union_out)
}

db_venn = function(
	args = NULL
) {
	# Get help
	if(length(args$help)>0) {      help     = args$help
    } else                         help     = FALSE
    if(help) {                     cat(help_message); quit() }

	# Global arguments
	if(length(args$base)>0)        b_path   = args$base
    if(length(args$out)>0)         out      = args$out
    if(length(args$debug)>0) {     debug    = args$debug
    } else                         debug    = FALSE

	# Reguired arguments
	if(length(args$fig)>0)         fig_path = args$fig
	if(length(args$uni_list)>0) {  uni_list = args$uni_list
	} else                         uni_list = TRUE
	if(length(args$sub_dir )>0) {  sub_dir  = args$sub_dir
	} else                         sub_dir  = FALSE
	if(length(args$uni_save)>0) {  uni_save = args$uni_save
	} else                         uni_save = TRUE
	if(length(args$ann_gwas)>0) {  ann_gwas = args$ann_gwas
	} else                         ann_gwas = NULL
	if(length(args$ann_encd)>0) {  ann_encd = args$ann_encd
	} else                         ann_encd = NULL
	if(length(args$ann_near)>0) {  ann_near = args$ann_near
	} else                         ann_near = NULL
	if(length(args$ann_cds )>0) {  ann_cds  = args$ann_cds
	} else                         ann_cds  = NULL
	if(length(args$ann_gtex)>0) {  ann_gtex = args$ann_gtex
	} else                         ann_gtex = NULL
	if(length(args$ann_lnc )>0) {  ann_lnc  = args$ann_lnc
	} else                         ann_lnc  = NULL

	# Run function
	source('src/pdtime.r'); t0=Sys.time()
    if(args$dbvenn == 'venn') {
		venn_bed(b_path,out,fig_path,uni_list)
	} else if(args$dbvenn == 'summ') {
		summ_ann(b_path,sub_dir,out,uni_save,ann_gwas,ann_encd,
			ann_near,ann_cds,ann_gtex,ann_lnc)
	} else {
		paste0('[Error] There is no such function "',args$dbfilt,'" in db_filter: ',
            paste0(args$ldlink,collapse=', '),'\n') %>% cat
	}
	paste0(pdtime(t0,1),'\n') %>% cat
}