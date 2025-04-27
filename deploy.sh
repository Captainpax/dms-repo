#!/bin/bash

# Move to this script's directory
cd "$(dirname "$0")" || exit 1

# Colors
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"

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

  echo -e "\n${CYAN}🔨 Building: ${BOLD}${image}${RESET}\n"
  pushd "$context" > /dev/null || exit 1
  docker build ${cache_opt} -t "${image}" -f "${dockerfile}" .
  docker push "${image}"
  popd > /dev/null || exit 1
}

# Docker cleanup function
docker_clean() {
  echo -e "${YELLOW}⚠️ Are you sure you want to prune ALL unused Docker images, containers, volumes? (y/N):${RESET}"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🧹 Cleaning up Docker system...${RESET}"
    docker system prune -af
    echo -e "${GREEN}✅ Docker cleanup complete.${RESET}"
  else
    echo -e "${RED}❌ Cleanup canceled.${RESET}"
  fi
}

# List of build targets
declare -A DOCKER_TARGETS=(
  ["1"]="dockers/base-img/ubuntu Dockerfile dms-base"
  ["2"]="dockers/vps/ubuntu Dockerfile dms-vps"
  ["3"]="dockers/games/gtav/fivem Dockerfile dms-fivem"
)

# Main Menu
while true; do
  clear
  echo -e "${BOLD}${CYAN}=========================================${RESET}"
  echo -e "${BOLD}${CYAN}🚀 Darkmatter Servers Docker Deployment Tool${RESET}"
  echo -e "${BOLD}${CYAN}=========================================${RESET}\n"
  echo -e "${BOLD}Menu Options:${RESET}"
  echo -e "  ${BOLD}1)${RESET} 🏗️  Build & Push Single Image"
  echo -e "  ${BOLD}2)${RESET} 🏗️  Build & Push All Images (Base -> VPS -> FiveM)"
  echo -e "  ${BOLD}3)${RESET} 🧹 Docker System Cleanup"
  echo -e "  ${BOLD}4)${RESET} ❌ Exit"
  echo ""
  echo -n "Enter choice [1-4, blank = Build All]: "
  read -r OPTION


  [[ -z "$OPTION" ]] && OPTION=2  # Default to build all if blank

  case $OPTION in
    1)
      echo -e "\n${BOLD}${CYAN}🏗️  Building a single image...${RESET}\n"

      read -rp "Docker tag [latest]: " input_tag
      [[ -n "$input_tag" ]] && TAG="$input_tag"

      read -rp "Use --no-cache? (Y/n): " input_nc
      [[ "$input_nc" =~ ^[Nn]$ ]] && CACHE_OPT="" || CACHE_OPT="--no-cache"

      read -rp "Docker namespace [captainpax]: " input_ns
      [[ -n "$input_ns" ]] && NAMESPACE="$input_ns"

      echo -e "\n${CYAN}Available Targets:${RESET}"
      echo "  1) dms-base (Ubuntu Base Image)"
      echo "  2) dms-vps (VPS SSH + UFW Utilities)"
      echo "  3) dms-fivem (FiveM Game Server)"
      echo ""
      read -rp "Select target number: " TARGET_SELECTION

      IFS=' ' read -r CONTEXT DOCKERFILE IMAGE_SUFFIX <<< "${DOCKER_TARGETS[$TARGET_SELECTION]}"
      if [[ -z "$CONTEXT" ]]; then
        echo -e "${RED}❌ Invalid target selection. Please try again.${RESET}"
        read -rp "Press Enter to continue..."
        continue
      fi

      IMAGE="${NAMESPACE}/${IMAGE_SUFFIX}:${TAG}"
      build_and_push "$CONTEXT" "$IMAGE" "$DOCKERFILE" "$CACHE_OPT"
      echo -e "\n${GREEN}✅ Successfully built and pushed ${image}${RESET}\n"
      ;;
    2)
      echo -e "\n${BOLD}${CYAN}🏗️  Building and pushing ALL images (Base -> VPS -> FiveM)...${RESET}\n"

      read -rp "Docker tag [latest]: " input_tag
      [[ -n "$input_tag" ]] && TAG="$input_tag"

      read -rp "Use --no-cache? (Y/n): " input_nc
      [[ "$input_nc" =~ ^[Nn]$ ]] && CACHE_OPT="" || CACHE_OPT="--no-cache"

      read -rp "Docker namespace [captainpax]: " input_ns
      [[ -n "$input_ns" ]] && NAMESPACE="$input_ns"

      for i in 1 2 3; do
        IFS=' ' read -r CONTEXT DOCKERFILE IMAGE_SUFFIX <<< "${DOCKER_TARGETS[$i]}"
        IMAGE="${NAMESPACE}/${IMAGE_SUFFIX}:${TAG}"
        build_and_push "$CONTEXT" "$IMAGE" "$DOCKERFILE" "$CACHE_OPT"
        echo -e "${GREEN}✅ Successfully built and pushed ${IMAGE}${RESET}\n"
      done
      ;;
    3)
      docker_clean
      ;;
    4)
      echo -e "\n${BLUE}👋 Exiting. Have a great day!${RESET}\n"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Invalid choice. Try again.${RESET}"
      ;;
  esac

  read -rp "Press Enter to return to the main menu..."
done
