#!/bin/bash
#SBATCH --job-name=mathlm
#SBATCH --partition=a40x
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8          # Crucial - only 1 task per dist per node!
#SBATCH --cpus-per-task=10          # Number of cores per tasks
#SBATCH --gres=gpu:8                 # Number of gpus
#SBATCH --output=slurmouts/llemma_7b_valid_%j.out      # Set this dir where you want slurm outs to go
#SBATCH --error=slurmouts/llemma_7b_valid_%j.out      # Set this dir where you want slurm outs to go
#SBATCH --exclusive      # Turn off node sharing
#SBATCH --account=neox
#SBATCH --open-mode=append
#SBATCH --requeue

source scripts/env.sh
echo $CUDA_HOME

MAX_ITERS=100
NUM_SAMPLES=32
TEMPERATURES="0.0"
TIMEOUT=600
NUM_SHARDS=8
DATASET="minif2f-valid"
DATA="data/minif2f.jsonl"

MODEL="EleutherAI/llemma_7b"
NAME="llemma7b"

OUTPUT_DIR="output/${NAME}_minif2f_valid"

for SHARD in {0..7};
do
  CONTAINER=native CUDA_VISIBLE_DEVICES=${SHARD} python proofsearch.py --dataset-name ${DATASET} --temperatures ${TEMPERATURES} --timeout ${TIMEOUT} --num-shards ${NUM_SHARDS} --shard ${SHARD} --model-name ${MODEL} --max-iters ${MAX_ITERS} --dataset-path ${DATA} --num-samples ${NUM_SAMPLES} --early-stop --output-dir ${OUTPUT_DIR} &> slurmouts/${NAME}_shard${SHARD}.out &
done

wait
