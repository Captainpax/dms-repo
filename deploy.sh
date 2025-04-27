#!/bin/bash

# Move to the script's directory
cd "$(dirname "$0")" || exit 1

# Colors
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; BLUE="\033[34m"

# Defaults
TAG="latest"
NAMESPACE="captainpax"
NO_CACHE=true

# Docker build function
build_and_push() {
  local context="$1"
  local image="$2"
  local dockerfile="$3"
  local cache_opt="$4"

  echo -e "${BLUE}🔨 Building: ${BOLD}${image}${RESET}"
  docker build $cache_opt -t "$image" -f "$dockerfile" "$context" && \
  docker push "$image"
}

# Docker cleanup function
docker_clean() {
  echo -e "${YELLOW}🧹 Performing Docker cleanup...${RESET}"
  docker system prune -af
  echo -e "${GREEN}✅ Cleanup completed.${RESET}"
}

# List of build targets
declare -A DOCKER_TARGETS=(
  ["1"]="base-ubuntu"
  ["2"]="vps-ubuntu"
  ["3"]="fivem"
)

# Mapping for build paths
get_build_info() {
  local selection="$1"
  case "$selection" in
    1)
      echo "dockers/base-img/ubuntu" "dockers/base-img/ubuntu/Dockerfile" "dms-base"
      ;;
    2)
      echo "dockers/vps/ubuntu" "dockers/vps/ubuntu/Dockerfile" "dms-vps"
      ;;
    3)
      echo "dockers/games/gtav/fivem" "dockers/games/gtav/fivem/Dockerfile" "dms-fivem"
      ;;
    *)
      echo "" "" ""
      ;;
  esac
}

# Interactive CLI menu
while true; do
  clear
  echo -e "${BOLD}====================================${RESET}"
  echo -e "${BOLD}🚀 DMS Docker Deployment Tool${RESET}"
  echo -e "${BOLD}====================================${RESET}"
  echo "1) 🏗️ Build & Push Docker Images"
  echo "2) 🧹 Docker Cleanup"
  echo "3) ❌ Exit"
  echo -n "Enter choice [1-3]: "
  read -r OPTION

  case $OPTION in
    1)
      read -rp "Docker tag [latest]: " input_tag
      [[ -n "$input_tag" ]] && TAG="$input_tag"

      read -rp "Use --no-cache? (Y/n): " input_nc
      [[ "$input_nc" =~ ^[Nn]$ ]] && CACHE_OPT="" || CACHE_OPT="--no-cache"

      read -rp "Docker namespace [captainpax]: " input_ns
      [[ -n "$input_ns" ]] && NAMESPACE="$input_ns"

      echo -e "\n${BLUE}Available build targets:${RESET}"
      for i in "${!DOCKER_TARGETS[@]}"; do
        echo "  $i) ${DOCKER_TARGETS[$i]}"
      done
      echo ""
      read -rp "Select a target number: " TARGET_SELECTION

      read -r CONTEXT DOCKERFILE IMAGE_SUFFIX <<< "$(get_build_info "$TARGET_SELECTION")"
      if [[ -z "$CONTEXT" ]]; then
        echo -e "${RED}❌ Invalid selection. Try again.${RESET}"
        read -rp "Press Enter to continue..."
        continue
      fi

      IMAGE="${NAMESPACE}/${IMAGE_SUFFIX}:${TAG}"
      build_and_push "$CONTEXT" "$IMAGE" "$DOCKERFILE" "$CACHE_OPT"
      echo -e "${GREEN}✅ Successfully built and pushed ${IMAGE}${RESET}"
      ;;
    2)
      docker_clean
      ;;
    3)
      echo -e "${BLUE}👋 Goodbye!${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Invalid option. Try again.${RESET}"
      ;;
  esac
  read -rp "Press Enter to continue..."
done
