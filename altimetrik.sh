#!/bin/sh

printSuccessOrFailure() {
    if [ $? -eq 0 ]; then
        echo -e "\t [Success]";
    else
        echo -e "\t [Failure]";
    fi
}

clone() {
    if [ -d "$1" ]; then
        printf "${1} application already cloned, pulling the latest code";
        cd ${1} > /dev/null 2>&1;
        git pull > /dev/null 2>&1;
        printSuccessOrFailure
        cd - > /dev/null 2>&1;
    else
        printf "Cloning application: %s" "${1}";
        git clone https://github.com/sonirahul/${1}.git ${1} > /dev/null 2>&1
        printSuccessOrFailure
    fi
}

build() {
    printf "Building application: %s" "${1}";
    cd ${1} > /dev/null 2>&1;
    ./mvnw clean install -DskipTests=true > /dev/null 2>&1;
    printSuccessOrFailure
    cd - > /dev/null 2>&1;
}

run() {
    stop ${1} > /dev/null 2>&1;
    printf "Starting %s application on port: %s" "${1}" "${2}"
    java -jar -Dserver.port=${2} ${1}/target/${1}-0.0.1-SNAPSHOT.jar > ${1}.log 2>&1 &

}

start() {
    clone ${1};
    build ${1};
    run ${1} ${2};
    echo -e "\n";
}

stop() {
    printf "Stoping application: %s" "${1}";
    ps -ef | grep ${1}/target/${1} | grep -v grep | awk '{ print $2 }' | xargs kill > /dev/null 2>&1;
    printSuccessOrFailure
}


delete() {
    echo "Deleting application: ${1}";
    stop ${1};
    rm -rf ${1} > /dev/null 2>&1;
    rm ${1}.log > /dev/null 2>&1;
}

dockerUpFunc() {
    docker-compose -f ./docker-compose/docker-compose.yml up -d
}

dockerDownFunc() {
    docker-compose -f ./docker-compose/docker-compose.yml down
}

if [ "$#" -ne 1 ]; then
    echo "Wrong number of arguments. e.g. ./altimetrik.sh <option>";
    echo -e "Valid options are: \n\t 1. \"--start\" \t\t- clones, builds and starts the applications. \n\t 2. \"--stop\" \t\t- stops the applications. \n\t 3. \"--docker-up\" \t- starts the application using docker. \n\t 4. \"--docker-down\" \t- stops all the docker contianers. \n\t 5. \"--delete\" \t\t- deletes the repositories.";
    exit 1;
fi

if [ $1 == "--start" ]; then
    start "altimetrik-registry" "8761"; # -- Don't change this port
    start "altimetrik-gateway" "8080";
    start "altimetrik-greeting-service" "8081";
elif [ $1 == "--stop" ]; then
    stop "altimetrik-registry";
    stop "altimetrik-gateway";
    stop "altimetrik-greeting-service";
elif [ $1 == "--docker-up" ]; then
    dockerUpFunc;
elif [ $1 == "--docker-down" ]; then
    dockerDownFunc;
elif [ $1 == "--delete" ]; then
    delete "altimetrik-registry";
    delete "altimetrik-gateway";
    delete "altimetrik-greeting-service";
else
    echo "Wrong value for option is provided."
    echo -e "Valid options are: \n\t 1. \"--start\" \t\t- clones, builds and starts the applications. \n\t 2. \"--stop\" \t\t- stops the applications. \n\t 3. \"--docker-up\" \t- starts the application using docker. \n\t 4. \"--docker-down\" \t- stops all the docker contianers. \n\t 5. \"--delete\" \t\t- deletes the repositories.";
    exit 1;
fi

