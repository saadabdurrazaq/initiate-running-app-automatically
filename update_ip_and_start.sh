#!/bin/bash

# Get the current IP address in the range 192.168.*, 172.16.*, or 10.*
currentIp=$(hostname -I | awk '{print $1}')

if [[ $currentIp =~ ^(192\.168\.|172\.16\.|10\.) ]]; then
    echo "Current IP: $currentIp"
    export PGPASSWORD="your_pg_password"

    # SQL commands with dynamic IP replacement
    query1="ALTER SERVER your_database OPTIONS (SET host '127.0.0.1', SET port '5432');"
    query2="ALTER SERVER another_your_database OPTIONS (SET host '127.0.0.1', SET port '5432');"
    query3="ALTER SERVER another_your_database OPTIONS (SET host '127.0.0.1', SET port '5432');"

    # Run SQL queries
    psql -U postgres -d eams -c "$query1"
    if [ $? -ne 0 ]; then
        echo "Failed to update another_your_database server"
        exit 1
    fi

    psql -U postgres -d eams -c "$query2"
    if [ $? -ne 0 ]; then
        echo "Failed to update another_your_database server"
        exit 1
    fi

    psql -U postgres -d eams -c "$query3"
    if [ $? -ne 0 ]; then
        echo "Failed to update another_your_database server"
        exit 1
    fi

    echo "Database server configurations have been updated successfully"

    # Paths to environment files 
    envBEPath="/home/sead/dev/restek/eamms-be-main-juli/.env"
    envFEPath="/home/sead/dev/restek/fe/.env"
    envAbsensiFEPath="/home/sead/dev/restek/absensi-fe/.env"
    envMobilePath="/home/sead/dev/restek/EAMMS-MOBILE/lib/core/environment/app_environment.dart"

    # Update .env files
    sed -i "s|BASE_URL=http://.*|BASE_URL=http://$currentIp:5000/|" "$envBEPath"
    sed -i "s|URL_API=http://.*|URL_API=http://$currentIp:5000/|" "$envBEPath"
    sed -i "s|DATABASE_URL=postgres://postgres:your_pg_password@.*|DATABASE_URL=postgres://postgres:your_pg_password@$currentIp:5432/eams|" "$envBEPath"
    sed -i "s|DATABASE_TA_URL=postgres://postgres:your_pg_password@.*|DATABASE_TA_URL=postgres://postgres:your_pg_password@$currentIp:5432/another_your_database|" "$envBEPath"

    sed -i "s|VITE_STAGING_API_URL=http://.*|VITE_STAGING_API_URL=http://$currentIp:5000|" "$envFEPath"
    sed -i "s|VITE_STAGING_USER_API_URL=http://.*|VITE_STAGING_USER_API_URL=http://$currentIp:3001|" "$envFEPath" 

    sed -i "s|VITE_STAGING_API_URL=http://.*|VITE_STAGING_API_URL=http://$currentIp:5000|" "$envAbsensiFEPath"
    sed -i "s|VITE_STAGING_USER_API_URL=http://.*|VITE_STAGING_USER_API_URL=http://$currentIp:3001|" "$envAbsensiFEPath" 

    sed -i "s|baseURL = 'http://.*|baseURL = 'http://$currentIp|" "$envMobilePath"
    sed -i "s|baseURLAuth = 'http://.*|baseURLbaseURLAuth = 'http://$currentIp|" "$envMobilePath" 

    echo "Updated .env files with IP $currentIp"

    # Close any existing processes running on specific ports
    ports=(3001 3002) # Add ports as needed
    for port in "${ports[@]}"; do
        pid=$(lsof -ti:$port)
        if [[ -n $pid ]]; then
            kill -9 "$pid"
            echo "Released port $port by terminating process ID $pid"
        fi
    done

    # Start new processes for the defined tasks
    tasks=(
        "/home/sead/dev/restek/eamms-be-login:yarn start"
        "/home/sead/dev/restek/eamms-be-main-juli:yarn start"
        "/home/sead/dev/restek/fe:npm run dev"
        "/home/sead/dev/restek/absensi-fe:npm run dev"
    )

    for task in "${tasks[@]}"; do
        path=$(echo "$task" | cut -d':' -f1)
        command=$(echo "$task" | cut -d':' -f2-)
        # xfce4-terminal --execute bash -c "cd $path && $command; echo; echo 'Process stopped. Press Enter to continue...'; exec bash" &
        # fce4-terminal --tab --title="$(basename "$path")" --execute bash -c "cd '$path' && $command; echo; echo 'Process stopped. Press Enter to continue...'; exec bash" &
        xfce4-terminal --tab --title="$(basename "$path")" --working-directory="$path" \
        --execute bash -c "trap 'echo \"\nProcess terminated. You are now in $(basename \"$path\")\"; bash' INT; $command; bash" &
    
        echo "Started task: cd $path && $command"

        # Add a short delay between launching terminals to prevent issues
        sleep 1
    done

    echo "The .env file has been updated with currentIP: $currentIp and the app is started automatically."
else
    echo "No IP address found in the desired range. Please check your network connection."
fi
