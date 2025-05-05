#!/bin/bash

cd "$(dirname "$0")" || exit 1

# Colors
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"

# Defaults
TAG="latest"
NAMESPACE="captainpax"
SKIP_PUSH=false
REQUIRED_FOLDER="dockers/games/gtav/fivem/home/container"

check_required_folder() {
  echo -e "${CYAN}🔎 Validating required build folder...${RESET}"
  if [[ ! -d "$REQUIRED_FOLDER" ]]; then
    echo -e "${RED}❌ Missing required folder: $REQUIRED_FOLDER${RESET}"
    exit 1
  fi
}

get_exposed_ports() {
  local dockerfile="$1"
  grep -i '^EXPOSE' "$dockerfile" | awk '{for (i=2;i<=NF;i++) print $i}'
}

ensure_expose_ports_exist() {
  local dockerfile="$1"
  if ! grep -iq '^EXPOSE' "$dockerfile"; then
    echo -e "${YELLOW}⚠️ No EXPOSE lines found. Injecting fallback ports into Dockerfile...${RESET}"
    echo -e "\n# Added by deploy.sh fallback\nEXPOSE 30120/tcp 30120/udp 40120/udp" >> "$dockerfile"
  fi
}

generate_port_flags() {
  local dockerfile="$1"
  local port_list=()

  while read -r port; do
    [[ -z "$port" ]] && continue
    proto="tcp"
    [[ "$port" =~ /udp$ ]] && proto="udp"
    port_clean="${port%/*}"
    port_list+=("-p" "${port_clean}:${port_clean}/${proto}")
  done < <(get_exposed_ports "$dockerfile")

  echo "${port_list[@]}"
}

build_and_push() {
  local dockerfile="$1"
  local image="$2"

  echo -e "\n${CYAN}🔨 Building: ${BOLD}${image}${RESET}\n"

  if [[ ! -f "$dockerfile" ]]; then
    echo -e "${RED}❌ Dockerfile not found at $dockerfile${RESET}"
    exit 1
  fi

  ensure_expose_ports_exist "$dockerfile"
  check_required_folder
  docker build --no-cache -t "${image}" -f "$dockerfile" .

  if [[ "$SKIP_PUSH" == false ]]; then
    docker push "${image}"
  else
    echo -e "${YELLOW}⚠️ Skipping docker push (push disabled by user)${RESET}"
  fi
}

docker_clean() {
  echo -e "${YELLOW}⚠️ Prune ALL unused Docker data? (y/N):${RESET}"
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🧹 Cleaning up Docker system...${RESET}"
    docker system prune -af
    echo -e "${GREEN}✅ Docker cleanup complete.${RESET}"
  else
    echo -e "${RED}❌ Cleanup canceled.${RESET}"
  fi
}

declare -A DOCKER_TARGETS=(
  ["1"]="dockers/games/gtav/fivem/Dockerfile dms-fivem"
)

auto_build_and_run() {
  echo -e "\n${CYAN}🏗️  Auto-building with default settings...${RESET}"

  TAG="latest"
  NAMESPACE="captainpax"
  SKIP_PUSH=false

  IFS=' ' read -r DOCKERFILE IMAGE_SUFFIX <<< "${DOCKER_TARGETS[1]}"
  IMAGE="${NAMESPACE}/${IMAGE_SUFFIX}:${TAG}"

  build_and_push "$DOCKERFILE" "$IMAGE"
  echo -e "\n${GREEN}✅ Build completed. Image: ${IMAGE}${RESET}\n"

  echo -e "${YELLOW}📂 Would you like to upload custom files now? (y/N):${RESET}"
  read -r upload_confirm
  if [[ "$upload_confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}📂 You can now upload custom files (drag/drop or sync). Press Enter when ready to continue...${RESET}"
    read -r
  else
    echo -e "${BLUE}↩️ Skipping upload step.${RESET}"
  fi

  PORT_FLAGS=$(generate_port_flags "$DOCKERFILE")
  echo -e "${CYAN}📡 Port bindings:${RESET} $PORT_FLAGS"
  echo -e "${YELLOW}⚠️ DEBUG: docker run -it --rm $PORT_FLAGS $IMAGE${RESET}\n"
  docker run -it --rm $PORT_FLAGS "$IMAGE"
}

while true; do
  clear
  echo -e "${BOLD}${CYAN}=========================================${RESET}"
  echo -e "${BOLD}${CYAN}🚀 Darkmatter Servers Docker Deployment Tool${RESET}"
  echo -e "${BOLD}${CYAN}=========================================${RESET}\n"
  echo -e "${BOLD}Menu Options:${RESET}"
  echo -e "  ${BOLD}-1)${RESET} ⚙️  Auto Build & Run With Defaults"
  echo -e "  ${BOLD}1)${RESET}  🏗️  Build & Push FiveM Image"
  echo -e "  ${BOLD}2)${RESET}  🧹 Docker System Cleanup"
  echo -e "  ${BOLD}3)${RESET}  🚀 Start a Docker Container"
  echo -e "  ${BOLD}0)${RESET}  ❌ Exit"
  echo ""
  echo -n "Enter choice [-1 to 3]: "
  read -r OPTION

  case $OPTION in
    -1)
      auto_build_and_run
      ;;
    1)
      echo -e "\n${CYAN}🏗️  Preparing FiveM image build...${RESET}\n"

      read -rp "Docker tag [latest]: " input_tag
      [[ -n "$input_tag" ]] && TAG="$input_tag"

      read -rp "Docker namespace [captainpax]: " input_ns
      [[ -n "$input_ns" ]] && NAMESPACE="$input_ns"

      echo -e "${YELLOW}Push to Docker Hub after build? (y/N):${RESET}"
      read -r push_choice
      SKIP_PUSH=true
      [[ "$push_choice" =~ ^[Yy]$ ]] && SKIP_PUSH=false

      IFS=' ' read -r DOCKERFILE IMAGE_SUFFIX <<< "${DOCKER_TARGETS[1]}"
      IMAGE="${NAMESPACE}/${IMAGE_SUFFIX}:${TAG}"
      build_and_push "$DOCKERFILE" "$IMAGE"
      echo -e "\n${GREEN}✅ Successfully built ${IMAGE}${RESET}\n"
      ;;
    2)
      docker_clean
      ;;
    3)
      echo -e "\n${CYAN}Available Docker Images:${RESET}"
      docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"
      echo ""
      read -rp "Enter image name to start (e.g. captainpax/dms-fivem:latest): " IMAGE_NAME
      if [[ -z "$IMAGE_NAME" ]]; then
        echo -e "${RED}❌ No image specified. Returning to menu.${RESET}"
      else
        echo -e "${BLUE}🚀 Running container from image ${BOLD}${IMAGE_NAME}${RESET}..."

        IFS=' ' read -r DOCKERFILE IMAGE_SUFFIX <<< "${DOCKER_TARGETS[1]}"
        ensure_expose_ports_exist "$DOCKERFILE"
        PORT_FLAGS=$(generate_port_flags "$DOCKERFILE")

        echo -e "${CYAN}📡 Port bindings:${RESET} $PORT_FLAGS"
        echo -e "${YELLOW}⚠️ DEBUG: docker run -it --rm $PORT_FLAGS $IMAGE_NAME${RESET}\n"
        docker run -it --rm $PORT_FLAGS "$IMAGE_NAME"
      fi
      ;;
    0)
      echo -e "\n${BLUE}👋 Exiting. Have a great day!${RESET}\n"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Invalid option. Try again.${RESET}"
      ;;
  esac

  read -rp "Press Enter to return to the main menu..."
done