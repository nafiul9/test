#!/bin/bash

if [[ $1 == "-h" || $1 == "" ]]; then
    echo -e "\nUsage: get_SeqRec [-F|-P] [USER_ORGANISM|\"USR_Genus USR_species\"] [WGS|WXS|AMPLICON|RNA-Seq|RAD-Seq|ChIP-Seq|Hi-C]"
    echo -e "\nEnter search query organism for lists of sequence run archive information; If entering name with more than one word, use quotes"
    echo -e "\nExamples: get_SeqRec -P dog | get_SeqReads -F \"Canis lupis familaris\" RAD-Seq"
    echo -e "\noption flags:"
    echo -e "  -h\tPrint this help message."
    echo -e "  -P\tPartial mode: The script will provide a tab delimited table including SRR & SRS, library information, Scientific Name, sequencer information, and consent information for the organism; use awk/grep on provided SRA_info file to create filtered lists to provide to sequence downloader, seq_pull.sh. Alternately, see the full mode flag."
    echo -e "  -F\tFull mode: The script will create the same files as partial mode as well as a file with a list of run IDs from queried organism and it downloads specified sequence reads; This script requires SRA Toolkit, please load local/cluster module. When running get_SeqReads in full mode library strategy must be included after search organism."
    exit 0


elif [[ $# -lt 3 ]]; then

    echo "Please indicate -F or -P for full or partial run, followed by a search organism, followed by a library strategy for a table of NCBI's sequence information. Try -h for help"
    exit 0

elif [[ $1 == "-P" ]]; then
    org=$2
    genus=$(echo "$org"|awk '{print $1}')
    species=$(echo "$org"|awk '{print $2}')
    cdate=$(date|awk '{OFS="_"}{print $2,$3}')
    mkdir "$genus""$species"~"$cdate"
    cd "$genus""$species"~"$cdate" || exit
    echo "Moving into $genus$species~$cdate/ ..."
    echo ""
    echo ""
    echo "========================================================================================================================="
    echo "Running Grab-N-Go Genomes in partial mode. All SRA search results for $org with public consent and SRR prefix will output to $genus$species~full_SRA_info_$cdate.txt"
    echo "Use awk/grep to filter output and run pull_SeqRec USR_ORGN. Prompt will ask for SRA_info file to pull SRR IDs, default is last created SRA_info file for indicated USR_ORGN."
    echo ""
    echo ""
    echo "Run_ID    Lib_Size(MB)    Lib_Type    Sample_ID    Scientific_Name    Sequencing_Platform    Model    Consent        $cdate" > "$genus""$species"~full_SRA_info_"$cdate".txt
    esearch -db sra -query "$org [ORGN]"|
    efetch -format runinfo -mode xml |
    xtract -pattern Row -tab "\t" -sep "," -def "BLANK" -element Run size_MB LibraryStrategy Sample ScientificName Platform Model Consent|
    awk -F "\t" '$8 == "public" {print $0}' | awk -F "\t" '/^SRR/ {print $0}'>> "$genus""$species"~full_SRA_info_"$cdate".txt
    Entries=$(tail -n +2 "$genus""$species"~full_SRA_info_"$cdate".txt | wc -l)
    echo "$Entries entries found. See $genus$species~full_SRA_info_$cdate.txt for more information."
    echo ""
    echo "To decrease downloading time, filtered output file for sequencing strategy indicated will be written to $genus$species~filtered_SRA_info_$cdate.txt. Use this file to create a list of SRR IDs as input for seq_pull.sh"
    echo "See line 87 of this script for command structure to produce input list for pull_SeqRec"
    strat=$3
    echo ""
    echo "Strategy used: $strat"
    awk '$3 == "'"$strat"'" {print $0}' "$genus""$species"~full_SRA_info_"$cdate".txt >> "$genus""$species"~filtered_SRA_info_"$cdate".txt
    Entries=$(tail -n +2 "$genus""$species"~filtered_SRA_info_"$cdate".txt | wc -l)
    echo "$Entries entries retain after filtering for $strat reads. See $genus$species~filtered_SRA_info_$cdate.txt for more information."
    echo ""
    exit 0



elif [[ $1 == "-F" ]]; then

    org=$2
    genus=$(echo "$org"|awk '{print $1}')
    species=$(echo "$org"|awk '{print $2}')
    cdate=$(date|awk '{OFS="_"}{print $2,$3}')
    mkdir "$genus""$species"~"$cdate"
    cd "$genus""$species"~"$cdate" || exit
    echo "Moving into $genus$species~$cdate/ ..."
    echo ""
    echo ""
    echo "========================================================================================================================="
    echo "Running Grab-N-Go Genomes in full mode. SRA search results in $genus$species~full_SRA_info_$cdate.txt will be filtered by indicated library strategy input at command line or prompt"
    echo "Filtered SRA info will be printed to $genus$species~filtered_SRA_info_$cdate.txt and used to create a list of SRR IDs $genus$species~run_accession_$cdate.txt"
    echo "for downloading sequences to the directory $genus$species~files_$cdate/"
    echo ""
    echo ""
    echo "Run_ID    Lib_Size(MB)    Lib_Type    Sample_ID    Scientific_Name    Sequencing_Platform    Model    Consent        $cdate" > "$genus""$species"~full_SRA_info_"$cdate".txt
    esearch -db sra -query "$org [ORGN]"|
    efetch -format runinfo -mode xml |
    xtract -pattern Row -tab "\t" -sep "," -def "BLANK" -element Run size_MB LibraryStrategy Sample ScientificName Platform Model Consent |
    awk -F "\t" '$8 == "public" {print $0}' | awk -F "\t" '/^SRR/ {print $0}' >> "$genus""$species"~full_SRA_info_"$cdate".txt
    Entries=$(tail -n +2 "$genus""$species"~full_SRA_info_"$cdate".txt | wc -l)
    echo "$Entries entries found. See $genus$species~full_SRA_info_$cdate.txt for more information."
    echo ""
    echo ""
    strat=$3
    echo ""
    echo "Strategy used: $strat"
    echo "Run_ID    Lib_Size(MB)    Lib_Type    Sample_ID    Scientific_Name    Sequencing_Platform    Model    Consent        $cdate" > "$genus""$species"~filtered_SRA_info_"$cdate".txt
    awk '$3 == "'"$strat"'" {print $0}' "$genus""$species"~full_SRA_info_"$cdate".txt >> "$genus""$species"~filtered_SRA_info_"$cdate".txt
    Entries=$(tail -n +2 "$genus""$species"~filtered_SRA_info_"$cdate".txt | wc -l)
    echo "$Entries entries retain after filtering for $strat reads. See $genus$species~filtered_SRA_info_$cdate.txt for more information."
    echo ""
    echo ""
    echo "Creating SRR list from $genus$species~filtered_SRA_info_$cdate.txt ..."
    echo ""
    awk '{print $1}' "$genus""$species"~filtered_SRA_info_"$cdate".txt| tail -n +2 > "$genus""$species"~run_accession_"$cdate".txt
fi


runs="$genus$species~run_accession_$cdate.txt"
if [[ ! -s $runs ]]; then
    echo "File is empty. Please provide SRR list; try seq_pull.sh -h for more information"
    exit 0
else
    asc="sra/2.8.1"
    pbs="sratoolkit/2.8.0"
    if [ "${HOSTNAME:0:9}" == "dmcvlogin" ]; then
        module load $asc
        echo "Loaded SRA Toolkit: $asc "
    elif [ -n "$PBS_JOBNAME" ]; then
            module load $pbs
        echo "Loaded SRA Toolkit: $pbs "
    fi
    mkdir "$genus""$species"~files_"$cdate"
    sd="./$genus$species~files_$cdate/"
    echo ""
    echo "Created the following directory for sequencing reads: $sd"
    echo " "
    echo "====================================================="

    add=0
    for run in $(cat "$runs" ); do
            let add++
            tot=$(cat "$runs"|wc -l)
            fastq-dump -v --split-files -I --gzip -O "$sd" "$run"

            echo "$add of $tot sequences downloaded to $sd"
            echo "----------------------------------------"
    done

    echo " "
    echo "====================================================="
    echo "Download Complete! Sequences can be found in $sd"

fi
