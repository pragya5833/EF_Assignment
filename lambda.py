import json
import boto3
import datetime
import calendar
import dateutil.parser
from botocore.session import Session
from botocore.config import Config

def lambda_handler(event, context):
    session = boto3.Session()
    currentRegion=session.region_name

    ec2Client = boto3.client('ec2')
    regionsAll=ec2Client.describe_regions().get('Regions',[])
    for region in regionsAll:
        currentRegion=region['RegionName']
        print(currentRegion)
        ec2 = session.resource('ec2', currentRegion)
        ec2Client = boto3.client('ec2', currentRegion)
        instances = ec2.instances.filter(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])
        for instance in instances:
            print(instance.tags)
            if instance.tags[0]['Key']=='ins' and instance.tags[0]['Value']=='one':
                current_date=datetime.date.today()
                dayOfWeek=calendar.day_name[current_date.weekday()]
                last_day = current_date.replace(day=calendar.monthrange(current_date.year, current_date.month)[1])
                name="ec2AMI_"+current_date.strftime('%Y-%m-%d') + "_"+ dayOfWeek
                print(name)
                ec2Client.create_image(InstanceId=instance.id,NoReboot=True,Name=name,TagSpecifications=[
                {
                    'ResourceType': 'image',
                    'Tags': [
                        {
                            'Key': 'insAMI',
                            'Value': 'oneAMI'
                     },
                 ]
                },
            ])
        def cleanup():
            amis = ec2Client.describe_images(Owners=['self'])
            for ami in amis['Images']:
                if 'Tags' in ami:
                    name = [tag['Value'] for tag in ami['Tags'] if tag['Key'] == 'insAMI'][0]
                    if ami['Name'].startswith("ec2AMI_"):
                        ami_id = ami['ImageId']
                        dateCreated = dateutil.parser.parse(ami['CreationDate']).date()
                        dayCreated=calendar.day_name[dateCreated.weekday()]
                        lastdayOfMonth=current_date.replace(day=calendar.monthrange(current_date.year, current_date.month)[1])
                        six_months_from_dateCreated = datetime.date(dateCreated.year + (dateCreated.month + 6)//12, (dateCreated.month + 6) % 12, dateCreated.day+1)
                        sevenDaysFromNow = current_date+datetime.timedelta(days=8)
                        print(dateCreated)
                        if dayCreated=='Sunday' and abs(current_date-dateCreated)==31:
                            print(f'deleting {ami_id} created on {dateCreated}')
                            ec2Client.deregister_image(ImageId=ami_id)
                        elif dateCreated==lastdayOfMonth and current_date==six_months_from_dateCreated:
                            print(f'deleting {ami_id} created on {dateCreated}')
                            ec2Client.deregister_image(ImageId=ami_id)
                        elif dayCreated=='Sunday' and dateCreated==lastdayOfMonth and abs(dateCreated-current_date)==366:
                            print(f'deleting {ami_id} created on {dateCreated}')
                            ec2Client.deregister_image(ImageId=ami_id)
                        elif dayCreated=='Thursday' and dateCreated==current_date:
                            print(f'deleting {ami_id} created on {dateCreated}')
                            ec2Client.deregister_image(ImageId=ami_id)
                        else:
                            if abs(current_date-dateCreated)==8:
                                ec2Client.deregister_image(ImageId=ami_id)







        cleanup()

        # if "Sunday" in name:
        #     print("delete after 30 days")
        # images = ec2.images.filter(Filters=[{'Name':'tag:Name', 'Values':['ec2AMI_*']}])
        # elif "30" or "31" in name:
        #     print("delete after 6 months")
        # elif "Sunday" in name and ("30"  or "31") in name:
        #     print("retain for a year")
        # else:
        #     print("retain for 7 days")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }










