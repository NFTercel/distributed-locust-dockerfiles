# Locust Docker for distributed mode
Docker of Locust for distributed mode.
Automatically downloading scenario files from AWS S3

## Environment Variables:

* S3_SCENARIO_PATH: Path of scenario files in AWS S3
* TARGET_URL: Target URL
* AWS_ACCESS_KEY_ID:
* AWS_SECRET_ACCESS_KEY:
* LOCUST_MODE: "master" or "slave" for distributed mode
* LOCUST_MASTER_HOST: host of master in distributed mode

## Usage
### Prepare Environment Variables
```
export S3_SCENARIO_PATH=locust/api_a
export TARGET_URL=http://host.docker.internal:8080
export AWS_ACCESS_KEY_ID=aaa
export AWS_SECRET_ACCESS_KEY=bbb
```
### Prepare Scenario files
Upload Locust scenario file `locustfile.py` to S3 ($S3_SCENARIO_PATH)

### Run Scenario local with docker-compose
```
docker-compose up
```
Multiple slave: 
```
docker-compose up --scale slave=3  # 1 master + 3 slave
```