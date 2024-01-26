from os import listdir, path
from snakemake.utils import min_version


# Settings
min_version("7.32.4")


# ------------- #
# Config        #
# ------------- #

BUILDS = config["builds"]
FILTER = config["filter"]
SOURCE = config["source"]
INSTALL_DIR = config["install_dir"]
BLACKLIST_HG19_URL = config["blacklist_hg19"]
BLACKLIST_HG38_URL = config["blacklist_hg38"]

# ------------- #
# I/O           #
# ------------- #

# Raw PWM and TFBS download
INSTALLED_GENOME = path.join(INSTALL_DIR, "{build}", "{build}.fa.gz")
INSTALLED_BLACKLIST = path.join(INSTALL_DIR, "{build}", "{build}.blacklist.bed")

# ------------- #
# Rules         #
# ------------- #


rule all:
    input:
        expand(INSTALLED_GENOME, build=BUILDS),
        expand(INSTALLED_BLACKLIST, build=BUILDS),


rule install_genome:
    message:
        """
        Installs target genome(s) under install dir
        - Regex to filter down to main chromosomes
        - Default provider set to UCSC
        """
    output:
        INSTALLED_GENOME,
    params:
        regex=FILTER,
        source=SOURCE,
        outdir=lambda op, output: path.dirname(os.path.dirname(output[0])),
    conda:
        "../envs/genome.yaml"
    threads: 24
    cache: True
    log:
        stdout="workflow/logs/install_genome-{build}.stdout",
        stderr="workflow/logs/install_genome-{build}.stderr",
    shell:
        """
        genomepy plugin disable blacklist &&
        genomepy install {wildcards.build} \
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
        INSTALLED_BLACKLIST,
    params:
        url=lambda wildcards: BLACKLIST_HG19_URL
        if wildcards.build == "hg19"
        else BLACKLIST_HG38_URL,
    conda:
        "../envs/genome.yaml"
    threads: 1
    log:
        stdout="workflow/logs/install_blacklist-{build}.stdout",
        stderr="workflow/logs/install_blacklist-{build}.stderr",
    shell:
        "wget -O - {params.url} | gunzip > {output}"
