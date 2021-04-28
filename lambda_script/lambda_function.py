""" Webサーバのアクセス集中時の対応スクリプト
    
    EC2を起動し起動を確認後ALBのターゲットに加えます。
    RDSのインスタンスクラスを指定されたクラスに変更します。
    *前提条件 
        ALB - EC2 - RDS の構成を想定しています。
        ALBのTargetGroupが作成されていてALBに紐付けされていること。
        停止中のEC2が一台あること。このEC2が本スクリプトの起動対象です。
        RDSは起動中であること。
        一通り動くものとして作成しています。設計書はありません。
    
    ToDo:
        定数はLambdaの環境変数から取得するようにしたい(済)
        テスト項目を作ってテストしたい(未対応)
"""
import json
import os
import sys
import boto3
import time
from datetime import datetime

""" 定数
    Lambdaの環境変数から設定します。

    """
REGION = os.environ['REGION']
INSTANCE_EC2_ID = os.environ['INSTANCE_EC2_ID']
INSTANCE_RDS_ID = os.environ['INSTANCE_RDS_ID']
ALB_TARGET_GROUP_ARN = os.environ['ALB_TARGET_GROUP_ARN']
RDS_TARGET_INSTANCE_CLASS = os.environ['RDS_TARGET_INSTANCE_CLASS']


def logger(log_lv, function_name, msg):
    """ ログ出力関数
    出力はCloudWatchLogs>ロググループで確認できる

    Args:
        log_lv ([string]): エラーレベル
        function_name ([string]): 関数の名前
        msg ([string]): メッセージ

    Examples:
        >>> logger("info", context.function_name, "実行開始")
               loggingTest [info] start

    """
    print(function_name + " [" + log_lv + "] " + msg)
    return


def lambda_handler(event, context):
    """ ラムダハンドラー
    1. EC2を起動する
    2. ALBのリスナーグループへ追加する
    3. RDSのスケールアップする

    Args:
        event ([type]): [description]
        context ([type]): [description]

    Returns:
        [string]: [description]
    """
    logger("info", context.function_name, "lambda start")
    logger("info", context.function_name, "REGION = " + REGION)

    """ 1. EC2を起動
    ToDo:
        response_startの中身を確認したい。jsonの構造の確認は必要。
    """
    ec2 = boto3.resource('ec2', REGION)
    instance = ec2.Instance(INSTANCE_EC2_ID)
    response_start = instance.start(DryRun=False)
    http_status_code = response_start['ResponseMetadata']['HTTPStatusCode']
    # コマンドがエラーで返ってきたら処理を終了
    if not (http_status_code == 200):
        logger("error", context.function_name,
               "ec2 instance " + INSTANCE_EC2_ID + " start is failed")
        logger("error", context.function_name, response_start)
        return {
            "status": "error",
            "body": json.dumps({
                "message": "エラーで終了しました",
            }),
        }
    logger("info", context.function_name,
           "ec2 instance " + INSTANCE_EC2_ID + " during startup")

    instance.wait_until_running()
    logger("info", context.function_name,
           "ec2 instance " + INSTANCE_EC2_ID + " started")
    """ 2. ALBのターゲットグループへ追加
    """
    elb = boto3.client('elbv2')
    response_register_targets = elb.register_targets(
        TargetGroupArn=ALB_TARGET_GROUP_ARN,
        Targets=[
            {
                'Id': INSTANCE_EC2_ID,
                'Port': 80,
            },
        ]
    )
    http_status_code = response_register_targets['ResponseMetadata']['HTTPStatusCode']
    # コマンドがエラーで返ってきたら処理を終了
    if not (http_status_code == 200):
        logger("error", context.function_name,
               "TargetGroup " + ALB_TARGET_GROUP_ARN + " register_targets is failed")
        logger("error", context.function_name, response_register_targets)
        return {
            "status": "error",
            "body": json.dumps({
                "message": "エラーで終了しました",
            }),
        }
    logger("info", context.function_name,
           "TargetGroup " + ALB_TARGET_GROUP_ARN + " register targets ec2 " + INSTANCE_EC2_ID)
    """
    Note:
    response_register_targets の例
     {'ResponseMetadata': {'RequestId': 'a5f21423-c856-458e-aa7a-535a87c8780a', 'HTTPStatusCode': 200, 'HTTPHeaders': {'x-amzn-requestid': 'a5f21423-c856-458e-aa7a-535a87c8780a', 'content-type': 'text/xml', 'content-length': '253', 'date': 'Thu, 22 Apr 2021 14:00:01 GMT'}, 'RetryAttempts': 0}}
    """

    """ 3. RDSのスケールアップ
    """
    rds = boto3.client('rds')
    """
    ToDo: 
     RDSのステータスがstartであることを確認後停止としたい。インスタンスタイプは起動中のみ変更可能なため。(未対応)
     停止する前にRDSのスナップショットとるか→上記の理由で対応しない(済)
     停止後にスケールアップしたい→インスタンスのタイプを変更する実装をした(済)
    
    """
    response_describe_db_instances = rds.describe_db_instances(
        DBInstanceIdentifier=INSTANCE_RDS_ID,
    )
    """
    Note:
     response_describe_db_instances の中身は以下を参照
         https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds.html#RDS.Client.describe_db_instances
    """
    db_instance_status = response_describe_db_instances['DBInstances'][0]['DBInstanceStatus']
    if db_instance_status == "stopped":
        logger("error", context.function_name,
               "db_instance " + INSTANCE_RDS_ID + " status[stopped] is not expected ")
        logger("error", context.function_name, response_describe_db_instances)
        return {
            "status": "error",
            "body": json.dumps({
                "message": "エラーで終了しました",
            }),
        }
    db_instance_info = response_describe_db_instances['DBInstances'][0]
    logger("info", context.function_name,
           "db_instance " + INSTANCE_RDS_ID + " DBInstanceClass is " + db_instance_info['DBInstanceClass'])
    response_modify_db_instance = rds.modify_db_instance(
        DBInstanceIdentifier=INSTANCE_RDS_ID,
        DBInstanceClass=RDS_TARGET_INSTANCE_CLASS,
        ApplyImmediately=True
    )
    http_status_code = response_modify_db_instance['ResponseMetadata']['HTTPStatusCode']
    if not (http_status_code == 200):
        logger("error", context.function_name,
               "db_instance " + INSTANCE_RDS_ID + " modify_db_instance is failed")
        logger("error", context.function_name, response_modify_db_instance)
        return {
            "status": "error",
            "body": json.dumps({
                "message": "エラーで終了しました",
            }),
        }
    logger("info", context.function_name,
           "db_instance " + INSTANCE_RDS_ID + " modify_db_instance class receive request")

    rds = boto3.client('rds')
    response_describe_db_instances = rds.describe_db_instances(
        DBInstanceIdentifier=INSTANCE_RDS_ID,
    )
    # if not(response_describe_db_instances['DBInstances']):
    #    exit
    db_instance_info = response_describe_db_instances['DBInstances'][0]
    """
    Note:
    modifyが完了したタイミングを把握したい。
    modifyのコマンドをApplyImmediately=Trueのオプションを付けて実行すると
    DBInstanceStatusの値は以下のように変化する
    1. available
    2. modifying
    3. available
    modifyが完了したタイミングは3. availableとなる。
    3. availableを把握するために以下の対応を実施
    while文は 1. available => 2. modifyingになるまで待つ処理
    available_waiterは 2. modifying => 3. available になるまで待つ処理
    """

    # 1. available => 2. modifyingになるまで待つ
    # ToDo :済
    # PendingModifiedValues の値が入っていれば（True）
    while db_instance_info['PendingModifiedValues']:
        logger("info", context.function_name,
               "db_instance " + INSTANCE_RDS_ID + " modify_db_instance class pending")
        if db_instance_info['DBInstanceStatus'] != 'available':
            break
        time.sleep(10)
        rds = boto3.client('rds')
        response_describe_db_instances = rds.describe_db_instances(
            DBInstanceIdentifier=INSTANCE_RDS_ID,
        )
        db_instance_info = response_describe_db_instances['DBInstances'][0]
    logger("info", context.function_name,
           "db_instance " + INSTANCE_RDS_ID + " modify_db_instance class modifying")
    # 2. modifying => 3. available になるまで待つ
    available_waiter = rds.get_waiter('db_instance_available')
    available_waiter.wait(
        DBInstanceIdentifier=INSTANCE_RDS_ID
    )
    logger("info", context.function_name,
           "db_instance " + INSTANCE_RDS_ID + " modify_db_instance class modified")
    rds = boto3.client('rds')
    response_describe_db_instances = rds.describe_db_instances(
        DBInstanceIdentifier=INSTANCE_RDS_ID,
    )

    db_instance_info = response_describe_db_instances['DBInstances'][0]
    logger("info", context.function_name,
           "db_instance " + INSTANCE_RDS_ID + " DBInstanceClass is " + db_instance_info['DBInstanceClass'])
    return {
        "status": "success",
        "body": json.dumps({
            "message": "正常終了",
        }),
    }
