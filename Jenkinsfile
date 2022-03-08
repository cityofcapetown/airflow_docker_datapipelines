def label = "airflow-datapipeline-${UUID.randomUUID().toString()}"
podTemplate(label: label, yaml: """
    apiVersion: v1
    kind: Pod
    metadata:
        name: ${label}
        annotations:
            container.apparmor.security.beta.kubernetes.io/${label}: unconfined
    labels:
        app: ${label}
    spec:
      containers:
      - name: ${label}
        image: moby/buildkit:v0.9.2-rootless
        imagePullPolicy: IfNotPresent
        command:
        - cat
        tty: true
      nodeSelector:
        workload: batch
    """,
    slaveConnectTimeout: 3600
  ) {
    node(label) {
        stage('setup') {
            git branch: 'airflow2', credentialsId: 'jenkins-user', url: 'https://ds1.capetown.gov.za/ds_gitlab/OPM/airflow-datapipeline.git'
        }
        stage('kubernetes-v2') {
            retry(100) {
                container(label) {
                    withCredentials([usernamePassword(credentialsId: 'opm-data-proxy-user', passwordVariable: 'OPM_DATA_PASSWORD', usernameVariable: 'OPM_DATA_USER'),
                                     usernamePassword(credentialsId: 'docker-user', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh '''
                        ./bin/buildkit-docker.sh ${OPM_DATA_USER} ${OPM_DATA_PASSWORD} \\
                                                 ${DOCKER_USER} ${DOCKER_PASS} \\
                                                 "${PWD}" \\
                                                 "docker.io/cityofcapetown/airflow:kubernetes-v2"
                        sleep 60
                        '''
                    }
                    updateGitlabCommitStatus name: 'kubernetes-v2', state: 'success'
                }
            }
        }
    }
}