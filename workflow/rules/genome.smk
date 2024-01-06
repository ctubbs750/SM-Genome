from snakemake.utils import min_version


# Configuration
configfile: "config/config.yaml"


# Parameters
BUILDS = config["builds"]
FILTER = config["filter"]
SOURCE = config["source"]
BLACKLIST_HG19_URL = config["blacklist_hg19"]
BLACKLIST_HG38_URL = config["blacklist_hg38"]

# Settings
min_version("7.32.4")


rule all:
    input:
        expand("resources/data/genome/{BUILD}/{BUILD}.fa.gz", BUILD=BUILDS),
        expand("resources/data/genome/{BUILD}/{BUILD}.blacklist.bed", BUILD=BUILDS),
    default_target: True


rule install_genome:
    message:
        """
        Installs target genome(s) under install dir
        - Regex to filter down to main chromosomes
        - Default provider set to UCSC
        """
    output:
        "resources/data/genome/{BUILD}/{BUILD}.fa.gz",
    params:
        regex=FILTER,
        source=SOURCE,
        outdir=lambda op, output: os.path.dirname(os.path.dirname(output[0])),
    conda:
        "../envs/genome.yaml"
    threads: 24
    cache: True
    log:
        stdout="workflow/logs/install_genome-{BUILD}.stdout",
        stderr="workflow/logs/install_genome-{BUILD}.stderr",
    shell:
        """
        genomepy plugin disable blacklist &&
        genomepy install {wildcards.BUILD} \
        --provider {params.source} \
        --genomes_dir {params.outdir} \
        --bgzip \
        --threads {threads} \
        --regex {params.regex}
        """


rule install_blacklist:
    message:
        """
        Installs ENCODE blacklist BED file.
        """
    output:
        "resources/data/genome/{BUILD}/{BUILD}.blacklist.bed",
    params:
        hg19_url=BLACKLIST_HG19_URL,
        hg38_url=BLACKLIST_HG38_URL,
    conda:
        "../envs/genome.yaml"
    threads: 1
    log:
        stdout="workflow/logs/install_blacklist-{BUILD}.stdout",
        stderr="workflow/logs/install_blacklist-{BUILD}.stderr",
    shell:
        """
        if [ {wildcards.BUILD} == "hg19" ]
        then
            wget -O - {params.hg19_url} | gunzip > {output}
        else
            wget -O - {params.hg38_url} | gunzip > {output}
        fi
        """
