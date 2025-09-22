#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is for macOS only"
        exit 1
    fi
}

# Function to install Docker
install_docker() {
    print_status "🐳 Docker Installation Script for macOS"
    echo "========================================"
    
    check_macos
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_status "📦 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        print_success "Homebrew is already installed"
    fi
    
    # Update Homebrew
    print_status "🔄 Updating Homebrew..."
    brew update
    
    # Install Docker Desktop using Homebrew Cask
    print_status "🐳 Installing Docker Desktop..."
    if brew list --cask docker &> /dev/null; then
        print_success "Docker Desktop is already installed"
    else
        brew install --cask docker
    fi
    
    # Check if Docker Desktop is running
    print_status "🔍 Checking Docker Desktop status..."
    if pgrep -f "Docker Desktop" > /dev/null; then
        print_success "Docker Desktop is running"
    else
        print_status "🚀 Starting Docker Desktop..."
        open -a Docker
        
        # Wait for Docker to start
        print_status "⏳ Waiting for Docker to start (this may take a minute)..."
        while ! docker info &> /dev/null; do
            sleep 2
            echo -n "."
        done
        echo ""
        print_success "Docker is now running"
    fi
    
    # Verify installation
    print_status "🧪 Verifying Docker installation..."
    docker --version
    docker-compose --version
    
    # Test Docker with hello-world
    print_status "🧪 Testing Docker with hello-world container..."
    docker run --rm hello-world
    
    echo ""
    print_success "🎉 Docker setup completed successfully!"
    echo ""
    print_status "📋 Next steps:"
    echo "   • Docker Desktop should now be running in your Applications folder"
    echo "   • You can manage Docker settings from the Docker Desktop app"
    echo "   • Try running: docker run --rm -it alpine:latest sh"
    echo "   • Visit https://docs.docker.com/get-started/ for tutorials"
    echo ""
    print_status "💡 Useful commands:"
    echo "   docker ps                    # List running containers"
    echo "   docker images               # List images"
    echo "   docker system prune         # Clean up unused containers/images"
    echo "   docker-compose up           # Start services defined in docker-compose.yml"
}

# Function to remove Docker
remove_docker() {
    print_status "🗑️  Docker Removal Script for macOS"
    echo "===================================="
    
    check_macos
    
    # Confirm removal
    echo ""
    print_warning "This will completely remove Docker Desktop from your macOS system."
    print_warning "All Docker containers, images, and volumes will be deleted!"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
    
    # Stop Docker Desktop if running
    print_status "🛑 Stopping Docker Desktop..."
    if pgrep -f "Docker Desktop" > /dev/null; then
        osascript -e 'quit app "Docker Desktop"'
        sleep 3
        print_success "Docker Desktop stopped"
    else
        print_success "Docker Desktop was not running"
    fi
    
    # Remove Docker Desktop via Homebrew
    print_status "🗑️  Removing Docker Desktop via Homebrew..."
    if brew list --cask docker &> /dev/null; then
        brew uninstall --cask docker
        print_success "Docker Desktop uninstalled via Homebrew"
    else
        print_warning "Docker Desktop not found in Homebrew"
    fi
    
    # Remove Docker application manually if it exists
    if [ -d "/Applications/Docker.app" ]; then
        print_status "🗑️  Removing Docker.app from Applications..."
        sudo rm -rf "/Applications/Docker.app"
        print_success "Docker.app removed from Applications"
    fi
    
    # Remove Docker data and configuration files
    print_status "🗑️  Removing Docker data and configuration files..."
    
    # Remove Docker data directory
    if [ -d "$HOME/.docker" ]; then
        rm -rf "$HOME/.docker"
        print_success "Removed ~/.docker directory"
    fi
    
    # Remove Docker Desktop data
    if [ -d "$HOME/Library/Containers/com.docker.docker" ]; then
        rm -rf "$HOME/Library/Containers/com.docker.docker"
        print_success "Removed Docker Desktop container data"
    fi
    
    # Remove Docker Desktop preferences
    if [ -f "$HOME/Library/Preferences/com.docker.docker.plist" ]; then
        rm -f "$HOME/Library/Preferences/com.docker.docker.plist"
        print_success "Removed Docker Desktop preferences"
    fi
    
    # Remove Docker Desktop logs
    if [ -d "$HOME/Library/Logs/Docker Desktop" ]; then
        rm -rf "$HOME/Library/Logs/Docker Desktop"
        print_success "Removed Docker Desktop logs"
    fi
    
    # Remove Docker group and context data
    if [ -d "$HOME/Library/Group Containers/group.com.docker" ]; then
        rm -rf "$HOME/Library/Group Containers/group.com.docker"
        print_success "Removed Docker group containers"
    fi
    
    # Remove any remaining Docker processes
    print_status "🔍 Checking for remaining Docker processes..."
    if pgrep -f docker > /dev/null; then
        print_warning "Found running Docker processes, attempting to kill them..."
        sudo pkill -f docker || true
        sleep 2
    fi
    
    # Remove Docker CLI symlinks (if they exist)
    if [ -L "/usr/local/bin/docker" ]; then
        sudo rm -f "/usr/local/bin/docker"
        print_success "Removed docker CLI symlink"
    fi
    
    if [ -L "/usr/local/bin/docker-compose" ]; then
        sudo rm -f "/usr/local/bin/docker-compose"
        print_success "Removed docker-compose CLI symlink"
    fi
    
    # Clean up any remaining Homebrew dependencies
    print_status "🧹 Cleaning up Homebrew..."
    brew autoremove 2>/dev/null || true
    brew cleanup 2>/dev/null || true
    
    echo ""
    print_success "🎉 Docker has been completely removed from your macOS system!"
    echo ""
    print_status "📋 What was removed:"
    echo "   • Docker Desktop application"
    echo "   • All Docker containers, images, and volumes"
    echo "   • Docker configuration files and data"
    echo "   • Docker Desktop preferences and logs"
    echo "   • Docker CLI tools and symlinks"
    echo ""
    print_status "💡 To reinstall Docker later, run: make docker-setup"
}

# Function to show usage
show_usage() {
    echo "Docker Management Script for macOS"
    echo ""
    echo "Usage: $0 {install|remove|help}"
    echo ""
    echo "Commands:"
    echo "  install    Install Docker Desktop on macOS"
    echo "  remove     Completely remove Docker Desktop from macOS"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install"
    echo "  $0 remove"
    echo "  make docker-setup    (via Makefile)"
    echo "  make docker-remove   (via Makefile)"
}

# Main script logic
case "${1:-help}" in
    install)
        install_docker
        ;;
    remove)
        remove_docker
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac