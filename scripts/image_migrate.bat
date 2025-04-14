@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM 初始化变量为默认值
SET "SOURCE_REPO=docker.io"
SET "TARGET_REPO=reg.homelab.lan"
SET "IMAGES_FILE=images.txt"

REM 检查命令行参数
:paramLoop
if "%~1"=="" goto :paramDone
if /i "%~1"=="/s" set "SOURCE_REPO=%~2" & shift & shift & goto :paramLoop
if /i "%~1"=="/t" set "TARGET_REPO=%~2" & shift & shift & goto :paramLoop
if /i "%~1"=="/i" set "IMAGES_FILE=%~2" & shift & shift & goto :paramLoop
shift & goto :paramLoop

:paramDone

REM 显示最终使用的值（可选）
echo 使用源仓库: %SOURCE_REPO%
echo 使用目标仓库: %TARGET_REPO%
echo 使用镜像文件: %IMAGES_FILE%

REM 读取Docker登录信息（如果需要的话，可以注释掉或改为使用更安全的登录方式）
REM echo 登录Docker Hub...
REM docker login --username=your_username --password=your_password

REM 遍历images.txt文件中的每一行（后续代码与原始脚本相同）
for /f "delims=" %%i in (%IMAGES_FILE%) do (
    set "IMAGE=%%i"
    
    REM 提取镜像名称和标签
    for /f "tokens=1,2 delims=/" %%a in ("!IMAGE!") do (
        set "REPO=%%a"
        set "IMG_NAME_TAG=%%b"
    )
    for /f "tokens=1,2 delims=:" %%c in ("!IMG_NAME_TAG!") do (
        set "IMG_NAME=%%c"
        set "TAG=%%d"
    )
    
    REM 构造源镜像和目标镜像名称
    set "SOURCE_IMAGE=!SOURCE_REPO!/!IMG_NAME!:!TAG!"
    set "TARGET_IMAGE=!TARGET_REPO!/!IMG_NAME!:!TAG!"
    
    REM 拉取镜像
    echo 拉取镜像: !SOURCE_IMAGE!
    docker pull !SOURCE_IMAGE!
    if !errorlevel! neq 0 (
        echo 拉取镜像失败: !SOURCE_IMAGE!
        exit /b 1
    )
    
    REM 标记镜像为新的仓库路径
    echo 标记镜像: !SOURCE_IMAGE! 为 !TARGET_IMAGE!
    docker tag !SOURCE_IMAGE! !TARGET_IMAGE!
    if !errorlevel! neq 0 (
        echo 标记镜像失败: !SOURCE_IMAGE!
        exit /b 1
    )
    
    REM 推送到新的镜像仓库
    echo 推送到目标仓库: !TARGET_IMAGE!
    docker push !TARGET_IMAGE!
    if !errorlevel! neq 0 (
        echo 推送镜像失败: !TARGET_IMAGE!
        exit /b 1
    )
    
    echo 镜像迁移成功: !TARGET_IMAGE!
)

REM 如果需要，登出Docker（可选）
REM docker logout

echo 所有镜像迁移完成。
endlocal
exit /b 0