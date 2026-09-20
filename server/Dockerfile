# Dockerfile —— 家庭共享(FamilyShare) 服务端镜像
# 多阶段构建：阶段一用 Maven 镜像把源码打成 fat jar；阶段二用精简 JRE 运行。
# 在 server/ 目录下执行：
#   docker build -t family-share-server:1.0.0 .
# （构建上下文必须是 server/，因为它需要 pom.xml、src/、update.json）

# ---------- 阶段一：构建 ----------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src

# 先只拷贝 pom.xml，利用 Docker 缓存加速（依赖没变就命中缓存）
COPY pom.xml .
RUN mvn -B -q dependency:go-offline || true

# 再拷贝源码与业务文件并打包
COPY src ./src
COPY update.json ./update.json
RUN mvn -B -q -DskipTests package

# ---------- 阶段二：运行 ----------
FROM eclipse-temurin:17-jre
WORKDIR /app

# 运行需要的文件都在工作目录 /app 下（update.json 是运行时必读的）
COPY --from=build /src/target/family-share-server.jar /app/app.jar
COPY update.json /app/update.json

# 图标/APK 目录挂载成卷持久化（见 docker-compose.yml）；bugs.json 写在 /app 根，非关键可留容器层
# 注意：本服务用 Java 17（pom.xml java.version=17），运行阶段必须用 17-jre，勿改成 25。
RUN mkdir -p /app/icons /app/downloads

# 中文应用默认东八区
ENV TZ=Asia/Shanghai

EXPOSE 3000
ENTRYPOINT ["java", "-jar", "/app/app.jar"]