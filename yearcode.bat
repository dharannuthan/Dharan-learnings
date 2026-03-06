# Replace <YOUR_REPO_URL> with your repository URL
REPO_URL="https://github.com/microgridtechsol/stat-app-api.git"

# Specify the starting and ending dates for the yearly range
START_DATE="2023-01-01"
END_DATE="2023-12-31"

# Clone the repository
git clone https://github.com/microgridtechsol/stat-app-api.git
cd repository

# Loop through each year
for year in $(seq $(date -d $START_DATE +%Y) $(date -d $END_DATE +%Y)); do
    # Calculate lines of code added and removed for each year
    git log --since="$year-01-01" --until="$((year+1))-01-01" --pretty=tformat: --numstat | awk '{ add += $1; remove += $2 } END { printf "Year %d: Added lines: %s Removed lines: %s\n", '$year', add, remove }'
done
