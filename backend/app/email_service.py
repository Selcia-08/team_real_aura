import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

# Email Configuration
SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME", "fairdispatch@example.com")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "your_app_password")
FROM_EMAIL = os.getenv("FROM_EMAIL", "fairdispatch@example.com")

def send_email(to_email: str, subject: str, body: str, html_body: str = None):
    """
    Send email notification to user
    For demo purposes, this will print to console instead of actually sending
    In production, configure with real SMTP credentials
    """
    try:
        # For demo - just log
        print(f"\n📧 EMAIL NOTIFICATION")
        print(f"To: {to_email}")
        print(f"Subject: {subject}")
        print(f"Body: {body}\n")
        
        # Uncomment below for actual email sending
        """
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = FROM_EMAIL
        msg['To'] = to_email
        
        text_part = MIMEText(body, 'plain')
        msg.attach(text_part)
        
        if html_body:
            html_part = MIMEText(html_body, 'html')
            msg.attach(html_part)
        
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
        """
        
        return True
    except Exception as e:
        print(f"❌ Email sending failed: {e}")
        return False

def send_route_assignment_email(driver_email: str, driver_name: str, route_desc: str, grade: str, explanation: str):
    subject = f"🚚 New Route Assignment - {grade} Grade"
    body = f"""
Hello {driver_name},

You have been assigned a new delivery route:

Route: {route_desc}
Difficulty: {grade}

Why this route?
{explanation}

Please log in to the FairDispatch app to view details and accept/decline this assignment.

Best regards,
FairDispatch AI Team
    """
    
    html_body = f"""
    <html>
        <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px;">
                <h2 style="color: #6C63FF;">🚚 New Route Assignment</h2>
                <p>Hello <strong>{driver_name}</strong>,</p>
                <p>You have been assigned a new delivery route:</p>
                
                <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
                    <p><strong>Route:</strong> {route_desc}</p>
                    <p><strong>Difficulty:</strong> <span style="color: {'green' if grade == 'Easy' else 'orange' if grade == 'Medium' else 'red'};">{grade}</span></p>
                </div>
                
                <div style="background: #e8f4f8; padding: 15px; border-radius: 8px; margin: 20px 0;">
                    <p><strong>Why this route?</strong></p>
                    <p style="font-style: italic;">{explanation}</p>
                </div>
                
                <p>Please log in to the FairDispatch app to view details and accept/decline this assignment.</p>
                
                <p style="margin-top: 30px; color: #666;">Best regards,<br>FairDispatch AI Team</p>
            </div>
        </body>
    </html>
    """
    
    return send_email(driver_email, subject, body, html_body)
