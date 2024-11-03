import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common import NoSuchElementException
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options as ChromeOptions
from tempfile import mkdtemp
import boto3


def check_exists_by_attribute(driver, attribute):
    try:
        driver.find_element(By.CSS_SELECTOR, attribute)
    except NoSuchElementException:
        return False
    return True


base_url = "https://www.recreation.gov/ticket/234640/ticket/"


def send_email(subject, body, sender, recipient):
    client = boto3.client('ses', region_name='us-east-1')
    response = client.send_email(
        Source=sender,
        Destination={
            'ToAddresses': [recipient]
        },
        Message={
            'Subject': {
                'Data': subject
            },
            'Body': {
                'Text': {
                    'Data': body
                }
            }
        }
    )
    print(response['MessageId'])

def lambda_handler(event, context):
    chrome_options = ChromeOptions()
    chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--disable-dev-tools")
    chrome_options.add_argument("--no-zygote")
    chrome_options.add_argument("--single-process")
    chrome_options.add_argument(f"--user-data-dir={mkdtemp()}")
    chrome_options.add_argument(f"--data-path={mkdtemp()}")
    chrome_options.add_argument(f"--disk-cache-dir={mkdtemp()}")
    chrome_options.add_argument("--remote-debugging-pipe")
    chrome_options.add_argument("--verbose")
    chrome_options.add_argument("--log-path=/tmp")
    chrome_options.binary_location = "/opt/chrome/chrome-linux64/chrome"

    service = Service(
        executable_path="/opt/chrome-driver/chromedriver-linux64/chromedriver",
        service_log_path="/tmp/chromedriver.log"
    )

    driver = webdriver.Chrome(
        service=service,
        options=chrome_options
    )

    extended = ("98", "extended historic tour")
    grand = ("100", "grand avenue tour")
    onyx = ("99", "onyx lantern tour")
    domes = ("1012", "domes and dripstones")
    urls = [extended, grand, onyx, domes]
    sent = False
    for url, name in urls:
        if sent:
            break
        driver.get(base_url + url)
        time.sleep(1)
        elem = driver.find_element(By.CSS_SELECTOR, "div[aria-label='month, ']")
        elem.send_keys("12")
        elem = driver.find_element(By.CSS_SELECTOR, "div[aria-label='day, ']")
        elem.send_keys("26")
        elem = driver.find_element(By.CSS_SELECTOR, "div[aria-label='year, ']")
        elem.send_keys("2024")
        if check_exists_by_attribute(driver, "div[data-component='RadioPillGroup']"):
            subject = "Hello from AWS Lambda"
            body = name + " is available."
            sender = "your_verified_email@example.com"
            recipient = "recipient_email@example.com"

            send_email(subject, body, sender, recipient)
        if not check_exists_by_attribute(driver, "div[data-component='RadioPillGroup']"):
            print(name + " is not available")
    driver.close()
    print("function completed")
