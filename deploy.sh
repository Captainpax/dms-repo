#!/bin/bash

# Move to this script's directory
cd "$(dirname "$0")" || exit 1

# Colors
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"

# Defaults
TAG="latest"
NAMESPACE="captainpax"
SKIP_PUSH=false

# Docker build function
build_and_push() {
  local context="$1"
  local image="$2"
  local dockerfile="$3"
  local cache_opt="$4"

  echo -e "\n${CYAN}🔨 Building: ${BOLD}${image}${RESET}\n"
  if [ ! -f "${context}/${dockerfile}" ]; then
    echo -e "${RED}❌ ERROR: Dockerfile not found at ${context}/${dockerfile}${RESET}"
    exit 1
  fi

  pushd "$context" > /dev/null || exit 1
  docker build ${cache_opt} -t "${image}" -f "${dockerfile}" .
  if [[ "$SKIP_PUSH" == false ]]; then
    docker push "${image}"
  else
    echo -e "${YELLOW}⚠️ Skipping docker push (SKIP_PUSH is true)${RESET}"
  fi
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

# Build targets (expandable later if needed)
declare -A DOCKER_TARGETS=(
  ["1"]="dockers/games/gtav/fivem Dockerfile dms-fivem"
)

# Main menu
while true; do
  clear
  echo -e "${BOLD}${CYAN}=========================================${RESET}"
  echo -e "${BOLD}${CYAN}🚀 Darkmatter Servers Docker Deployment Tool${RESET}"
  echo -e "${BOLD}${CYAN}=========================================${RESET}\n"
  echo -e "${BOLD}Menu Options:${RESET}"
  echo -e "  ${BOLD}1)${RESET} 🏗️  Build & Push FiveM Image"
  echo -e "  ${BOLD}2)${RESET} 🧹 Docker System Cleanup"
  echo -e "  ${BOLD}3)${RESET} 🚀 Start a Docker Container"
  echo -e "  ${BOLD}0)${RESET} ❌ Exit"
  echo ""
  echo -n "Enter choice [0-3, or -1 for instant build]: "
  read -r OPTION

  [[ -z "$OPTION" ]] && OPTION=1  # Default: build

  if [[ "$OPTION" == "-1" ]]; then
    echo -e "\n${BOLD}${CYAN}🏗️  Instant Building and Pushing Image...${RESET}\n"
    TAG="latest"
    CACHE_OPT="--no-cache"
    NAMESPACE="captainpax"

    echo -e "${YELLOW}Do you want to push image after build? (y/N):${RESET}"
    read -r push_choice
    if [[ "$push_choice" =~ ^[Yy]$ ]]; then
      SKIP_PUSH=false
    else
      SKIP_PUSH=true
    fi

    IFS=' ' read -r CONTEXT DOCKERFILE IMAGE_SUFFIX <<< "${DOCKER_TARGETS[1]}"
    IMAGE="${NAMESPACE}/${IMAGE_SUFFIX}:${TAG}"
    build_and_push "$CONTEXT" "$IMAGE" "$DOCKERFILE" "$CACHE_OPT"
    echo -e "${GREEN}✅ Successfully built ${IMAGE}${RESET}\n"

    read -rp "Press Enter to return to the main menu..."
    continue
  fi

  case $OPTION in
    1)
      echo -e "\n${BOLD}${CYAN}🏗️  Building FiveM Image...${RESET}\n"

      read -rp "Docker tag [latest]: " input_tag
      [[ -n "$input_tag" ]] && TAG="$input_tag"

      read -rp "Use --no-cache? (Y/n): " input_nc
      [[ "$input_nc" =~ ^[Nn]$ ]] && CACHE_OPT="" || CACHE_OPT="--no-cache"

      read -rp "Docker namespace [captainpax]: " input_ns
      [[ -n "$input_ns" ]] && NAMESPACE="$input_ns"

      echo -e "${YELLOW}Do you want to push after build? (y/N):${RESET}"
      read -r push_choice
      if [[ "$push_choice" =~ ^[Yy]$ ]]; then
        SKIP_PUSH=false
      else
        SKIP_PUSH=true
      fi

      IFS=' ' read -r CONTEXT DOCKERFILE IMAGE_SUFFIX <<< "${DOCKER_TARGETS[1]}"
      IMAGE="${NAMESPACE}/${IMAGE_SUFFIX}:${TAG}"
      build_and_push "$CONTEXT" "$IMAGE" "$DOCKERFILE" "$CACHE_OPT"
      echo -e "\n${GREEN}✅ Successfully built ${IMAGE}${RESET}\n"
      ;;
    2)
      docker_clean
      ;;
    3)
      echo -e "\n${CYAN}Available Docker Images:${RESET}"
      docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"
      echo ""
      read -rp "Enter image name to start (example: captainpax/dms-fivem:latest): " IMAGE_NAME
      if [[ -z "$IMAGE_NAME" ]]; then
        echo -e "${RED}❌ No image specified. Returning to menu.${RESET}"
      else
        echo -e "${BLUE}🚀 Starting container from image ${BOLD}${IMAGE_NAME}${RESET}..."
        docker run -it --rm "$IMAGE_NAME"
      fi
      ;;
    0)
      echo -e "\n${BLUE}👋 Exiting. Have a great day!${RESET}\n"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Invalid choice. Try again.${RESET}"
      ;;
  esac

  read -rp "Press Enter to return to the main menu..."
done