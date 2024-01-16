#!/bin/bash
#SBATCH --job-name=mathlm
#SBATCH --partition=a40x
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8          # Crucial - only 1 task per dist per node!
#SBATCH --cpus-per-task=10          # Number of cores per tasks
#SBATCH --gres=gpu:8                 # Number of gpus
#SBATCH --array=1-3
#SBATCH --output=slurmouts/llemma_f_7b_v0.1_valid_%a_%A.out      # Set this dir where you want slurm outs to go
#SBATCH --error=slurmouts/llemma_f_7b_v0.1_valid_%a_%A.out      # Set this dir where you want slurm outs to go
#SBATCH --exclusive      # Turn off node sharing
#SBATCH --account=neox
#SBATCH --open-mode=append
#SBATCH --requeue

source scripts/env.sh
echo $CUDA_HOME
echo $GITHUB_ACCESS_TOKEN

MAX_ITERS=100
NUM_SAMPLES=32
TEMPERATURES="0.0"
TIMEOUT=600
NUM_SHARDS=8
SPLIT=valid
DATASET="minif2f-${SPLIT}"
DATA="data/minif2f.jsonl"

models=(\
    "zhangirazerbayev/llemma_7b_f_v0.1_3e-5lr" \
    "zhangirazerbayev/llemma_f_7b_v0.1_altmix0" \
    "zhangirazerbayev/llemma_f_7b_v0.1_altmix1" \
    "zhangirazerbayev/llemma_f_7b_v0.1_4epoch" \
)

MODEL=${models[$SLURM_ARRAY_TASK_ID]}
NAME="${MODEL#*/}"
echo "HF MODEL ID: " $MODEL
echo "SAVE NAME: " $NAME

OUTPUT_DIR="output/${NAME}_minif2f_valid"

huggingface-cli download $MODEL

for SHARD in {0..7};
do
  CONTAINER=native CUDA_VISIBLE_DEVICES=${SHARD} python proofsearch.py --dataset-name ${DATASET} --temperatures ${TEMPERATURES} --timeout ${TIMEOUT} --num-shards ${NUM_SHARDS} --shard ${SHARD} --model-name ${MODEL} --max-iters ${MAX_ITERS} --dataset-path ${DATA} --num-samples ${NUM_SAMPLES} --early-stop --output-dir ${OUTPUT_DIR} &> slurmouts/${NAME}_${SPLIT}_shard${SHARD}.out &
done

wait
