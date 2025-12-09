qrcode:
  #!/usr/bin/env sh
  # Get the repository URL
  REPO_URL=$(git config --get remote.origin.url)
  # Extract the username and repository name
  USERNAME=$(echo $REPO_URL | awk -F'[/:]' '{print $(NF-1)}')
  REPO_NAME=$(basename $REPO_URL .git)
  # Format the GitHub Pages URL
  GH_PAGES_URL="https://$USERNAME.github.io/$REPO_NAME"
  # Generate the QR code
  segno $GH_PAGES_URL -o=files/qrcode.png --light transparent --scale 10