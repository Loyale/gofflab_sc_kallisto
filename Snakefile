from os.path import join
configfile: "config_kallisto.yaml"

kallisto=config["KALLISTO"]
bustools=config["BUSTOOLS"]
thread=config["THREAD"]
outprefix=config["OUTPUT"]
index=config["INDEX"]
#fastqs=config["FASTQS"]
chem=config["CHEM"]
tr2g=config["TR2G"]
whitelist=config["WHITELIST"]

sample_file = config["SAMPLE_FILE"]
sample_file_handle = open(sample_file,'r')
sample_keys = sample_file_handle.readline().rstrip().split()
samples_dict = {}
#print(sample_keys)
for line in sample_file_handle:
    vals = line.rstrip().split()
    vals_dict = dict(zip(sample_keys,vals))
    samples_dict.setdefault(vals_dict['sample'],
                                    {
                                    "R1_fastq":vals_dict['R1_fastq'],
                                    "R2_fastq":vals_dict['R2_fastq']
                                    }
                            )
samples = sorted(samples_dict.keys())
#print(samples)
#print(samples_dict)

rule all:
    input: expand("kallisto_out/{sample}/log.txt", sample=samples)

rule run_kallisto:
    output:
        "kallisto_out/{sample}/matrix.ec"
    benchmark:
        "benchmarks_kallisto/{sample}_1.txt"
    conda:
      "envs/kallistobus.yaml"
    shell:
        """
         rm -rf kallisto_out/{sample}
         {kallisto} bus -i {index} -x {chem} -t {thread} -o kallisto_out/{sample} {fastqs}
        """

rule run_correct_count:
    input:
        "kallisto_out/{sample}/matrix.ec"
    output:
        "kallisto_out/{sample}/log.txt"
    benchmark:
        "benchmarks_kallisto/{sample}_2.txt"
    conda:
      "envs/kallistobus.yaml"
    shell:
        """
         {bustools} correct -w {whitelist} -p kallisto_out/{sample}/output.bus | {bustools} sort -t {thread} -m 2G -T kallisto_out/{sample} -p - | {bustools} count -o kallisto_out/{sample}/genes -g {tr2g} -e kallisto_out/{sample}/matrix.ec -t kallisto_out/{sample}/transcripts.txt --genecounts -
         echo "Kallisto single cell pipeline is complete" > kallisto_out/{sample}/log.txt
        """
