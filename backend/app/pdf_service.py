from fpdf import FPDF
import os
from datetime import datetime

class PDFReport(FPDF):
    def header(self):
        self.set_font('Arial', 'B', 15)
        self.cell(0, 10, 'FairDispatch - Daily Assignment Report', 0, 1, 'C')
        self.ln(5)

    def footer(self):
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.cell(0, 10, 'Page ' + str(self.page_no()), 0, 0, 'C')

def generate_daily_report(assignments, location_id, date_str, output_dir="reports"):
    # Ensure output directory exists (absolute path relative to app execution or fixed)
    # We will use 'reports' folder in backend root usually
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    pdf = PDFReport()
    pdf.add_page()
    pdf.set_font('Arial', '', 12)
    
    pdf.cell(0, 10, f"Location: {location_id}", 0, 1)
    pdf.cell(0, 10, f"Date: {date_str}", 0, 1)
    
    # Tracking Link
    link = f"http://fairdispatch.app/track/{location_id}/{date_str}"
    pdf.cell(0, 10, f"Live Tracking: {link}", 0, 1, link=link)
    pdf.ln(5)
    
    # Table Header
    pdf.set_fill_color(200, 220, 255)
    pdf.set_font('Arial', 'B', 8)
    pdf.cell(30, 10, 'Driver Name', 1, 0, 'C', 1)
    pdf.cell(20, 10, 'Emp ID', 1, 0, 'C', 1)
    pdf.cell(40, 10, 'Route Area', 1, 0, 'C', 1)
    pdf.cell(15, 10, 'Level', 1, 0, 'C', 1)
    pdf.cell(85, 10, 'Assignment Reasoning & Math (AI Calculation)', 1, 1, 'C', 1)
    
    # Rows
    pdf.set_font('Arial', '', 7)
    for assignment in assignments:
        driver = assignment.driver
        route = assignment.route
        
        driver_name = driver.name[:15] if driver else "Unknown"
        emp_id = driver.employee_id if driver else "N/A"
        area = route.area[:20] if route else "N/A"
        
        # Handle Enum for grade
        grade_str = "N/A"
        if route and route.grade:
            try:
                grade_str = route.grade.name 
            except:
                grade_str = str(route.grade)
        
        explanation = assignment.explanation if assignment.explanation else "No reasoning provided."
        
        # We use multi_cell for the explanation if it's long, but for a table row we might need to handle it carefully
        # Or just use a smaller font and truncate or wrap
        
        x = pdf.get_x()
        y = pdf.get_y()
        
        pdf.cell(30, 10, driver_name, 1)
        pdf.cell(20, 10, emp_id, 1)
        pdf.cell(40, 10, area, 1)
        pdf.cell(15, 10, grade_str, 1)
        
        # Multi-cell for the final column
        pdf.multi_cell(85, 5, explanation, 1, 'L')
        
        # Set cursor back for next row if multi_cell moved it too much or ensure consistency
        # Actually multi_cell moves the cursor to the next line. 
        # But we need to make sure all cells in the row have the same height.
        # This is a bit complex with FPDF raw. Simplest is to just use a fixed height or multi_cell and draw rects.
        # However, for now, let's just use regular cell and hope it fits or use small font.
        
    filename = f"Dispatch_{location_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}.pdf"
    filepath = os.path.join(output_dir, filename)
    pdf.output(filepath, 'F')
    return filepath
