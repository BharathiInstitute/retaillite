# RetailLite — Print Feature Test Plan

> **Version**: v9.1.0+43
> **Date**: March 24, 2026
> **Scope**: All printing, receipt generation, and bill sharing features
> **Platforms**: Web (Chrome), Windows Desktop, Android

---

## 1. Test Environment Setup

### Prerequisites
| Item | Details |
|------|---------|
| Flutter SDK | 3.9.2+ |
| Chrome | Latest (Web testing) |
| Windows 10/11 | Desktop testing |
| Android device or emulator | Mobile testing |
| Bluetooth thermal printer | 58mm or 80mm (e.g., RPP02N, Xprinter) |
| WiFi thermal printer | Any ESC/POS printer on TCP:9100 |
| USB printer | Any Windows-recognized printer |
| Test shop account | With products, bills, and customer data |

### Test Data Requirements
- Minimum 5 products in inventory
- At least 1 completed bill (cash payment)
- At least 1 completed bill (udhaar/credit payment)
- At least 1 customer with phone number (for WhatsApp/SMS tests)
- Custom receipt footer configured in Settings > Hardware

---

## 2. Bluetooth Thermal Printer Tests (Android Only)

### 2.1 Device Discovery & Pairing

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| BT-01 | Scan paired devices | Settings > Hardware > Bluetooth > Scan | Lists all paired BT devices | ☐ |
| BT-02 | Connect to printer | Tap a printer from device list | Shows "Connected" status, green indicator | ☐ |
| BT-03 | Disconnect printer | Tap "Disconnect" button | Shows "Disconnected" status | ☐ |
| BT-04 | Saved printer auto-reconnect | Close & reopen app with saved printer | Auto-reconnects to last saved printer | ☐ |
| BT-05 | Invalid device handling | Try connecting to non-printer BT device | Shows error message, no crash | ☐ |
| BT-06 | Printer turned off | Try printing with printer powered off | Shows "Printer not available" error | ☐ |

### 2.2 Bluetooth Printing

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| BT-07 | Test print | Settings > Hardware > Test Print | Prints test page with alignment checks | ☐ |
| BT-08 | Print cash receipt | Complete a cash bill | Receipt prints: header, items, totals, footer | ☐ |
| BT-09 | Print udhaar receipt | Complete an udhaar bill | Receipt shows "PAYMENT PENDING" warning | ☐ |
| BT-10 | 58mm paper format | Set paper size = 58mm, print | 32 chars/line, text wraps correctly | ☐ |
| BT-11 | 80mm paper format | Set paper size = 80mm, print | 48 chars/line, wider columns | ☐ |
| BT-12 | Font size Small | Set font = Small, print | Smaller text, more content per line | ☐ |
| BT-13 | Font size Normal | Set font = Normal, print | Standard readable text | ☐ |
| BT-14 | Font size Large | Set font = Large, print | Larger text, less content per line | ☐ |
| BT-15 | Custom footer | Set footer text, print | Footer appears at bottom of receipt | ☐ |
| BT-16 | Hindi/₹ characters | Bill with Hindi product names | Hindi text and ₹ symbol render correctly | ☐ |
| BT-17 | Long product name | Product with 40+ char name | Name wraps without breaking layout | ☐ |
| BT-18 | Multi-item bill | Bill with 10+ items | All items print, totals correct | ☐ |
| BT-19 | Auto-print on billing | Enable auto-print, complete a bill | Receipt prints immediately after save | ☐ |
| BT-20 | Auto-print disabled | Disable auto-print, complete a bill | No auto-print, manual print available in dialog | ☐ |

---

## 3. WiFi/Network Thermal Printer Tests (Windows, Android)

### 3.1 Connection

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| WF-01 | Connect with IP:port | Settings > Hardware > WiFi > Enter IP, Port 9100 > Connect | Shows "Connected" with green indicator | ☐ |
| WF-02 | Invalid IP address | Enter non-existent IP > Connect | Shows connection timeout error | ☐ |
| WF-03 | Wrong port | Enter correct IP, wrong port > Connect | Shows connection refused error | ☐ |
| WF-04 | Disconnect | Tap Disconnect | Shows "Disconnected" status | ☐ |
| WF-05 | Connection persistence | Save WiFi printer, restart app | Auto-reconnects to saved IP:port | ☐ |
| WF-06 | Network drop during print | Disconnect WiFi mid-print | Error message, no crash, receipt data not lost | ☐ |

### 3.2 WiFi Printing

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| WF-07 | Test print | Settings > Hardware > Test Print | Test page prints on network printer | ☐ |
| WF-08 | Print cash receipt | Complete a cash bill | Full receipt prints via TCP | ☐ |
| WF-09 | Print udhaar receipt | Complete an udhaar bill | Shows "PAYMENT PENDING" on receipt | ☐ |
| WF-10 | 58mm format | Paper=58mm, print | 32 chars/line formatting | ☐ |
| WF-11 | 80mm format | Paper=80mm, print | 48 chars/line formatting | ☐ |
| WF-12 | Concurrent prints | Rapidly complete 2 bills | Both receipts print in order, no data mixing | ☐ |

---

## 4. USB Thermal Printer Tests (Windows Only)

### 4.1 Device Management

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| USB-01 | List Windows printers | Settings > Hardware > USB | Dropdown shows all installed printers | ☐ |
| USB-02 | Select printer | Choose printer from dropdown | Printer name saved, shown as selected | ☐ |
| USB-03 | Printer not found | Disconnect USB printer, try print | Error message: printer unavailable | ☐ |

### 4.2 USB Printing

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| USB-04 | Test print | Settings > Hardware > Test Print | Test page via Windows spooler | ☐ |
| USB-05 | Print cash receipt | Complete a cash bill | Receipt prints via USB | ☐ |
| USB-06 | Print udhaar receipt | Complete an udhaar bill | "PAYMENT PENDING" on receipt | ☐ |
| USB-07 | 58mm + 80mm formats | Switch paper size, print both | Correct formatting per size | ☐ |

---

## 5. System Printer / PDF Tests (All Platforms)

### 5.1 System Print Dialog

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| SYS-01 | Print via system dialog (Web) | Set printer=System, print bill | Browser print dialog opens with PDF preview | ☐ |
| SYS-02 | Print via system dialog (Windows) | Set printer=System, print bill | Windows print dialog with printer selection | ☐ |
| SYS-03 | Print via system dialog (Android) | Set printer=System, print bill | Android print dialog opens | ☐ |
| SYS-04 | Cancel print dialog | Open print dialog, click Cancel | No print, no error, returns to app | ☐ |
| SYS-05 | Print preview enabled | Enable print preview in settings | Preview shown before printing | ☐ |

### 5.2 PDF Receipt Generation

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| PDF-01 | PDF 57mm roll format | Generate receipt with 58mm setting | PDF dimensions: 80.76 × 203.2mm | ☐ |
| PDF-02 | PDF 80mm roll format | Generate receipt with 80mm setting | PDF dimensions: 110.5 × 203.2mm | ☐ |
| PDF-03 | Shop logo on PDF | Set shop logo, generate PDF | Logo appears at top of receipt | ☐ |
| PDF-04 | QR code on PDF | Generate receipt | QR code rendered on PDF receipt | ☐ |
| PDF-05 | GST details on PDF | Shop has GST number set | GSTIN appears in header section | ☐ |
| PDF-06 | Custom footer on PDF | Set receipt footer, generate PDF | Footer text at bottom of PDF | ☐ |
| PDF-07 | Multi-item PDF | Bill with 15+ items, generate PDF | All items listed, page extends if needed | ☐ |

---

## 6. Bill Sharing Tests (All Platforms)

### 6.1 WhatsApp Share

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| WA-01 | Share to WhatsApp (direct) | Bill complete > Share > WhatsApp with phone | Opens WhatsApp chat with pre-filled message | ☐ |
| WA-02 | Share to WhatsApp (general) | Bill complete > Share > WhatsApp | Opens share sheet, select WhatsApp | ☐ |
| WA-03 | WhatsApp not installed | Try share on device without WhatsApp | Graceful error: "WhatsApp not installed" | ☐ |
| WA-04 | Bill text format | Verify shared WhatsApp message | Contains: shop name, items, totals, bill# | ☐ |

### 6.2 SMS Share

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| SMS-01 | Share via SMS | Bill complete > Share > SMS | Opens SMS app with formatted bill text | ☐ |
| SMS-02 | SMS text format | Check SMS content | Contains bill details with emoji formatting | ☐ |

### 6.3 PDF Share & Download

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| PDF-08 | Download PDF | Bill complete > Download PDF | PDF saved to device, A5 invoice format | ☐ |
| PDF-09 | General share | Bill complete > Share | System share sheet opens with PDF attachment | ☐ |
| PDF-10 | A5 invoice format | Download PDF, open | 148×210mm, professional invoice layout | ☐ |

---

## 7. Receipt Content Validation

### 7.1 Receipt Fields

| # | Test Case | Expected on Receipt | Status |
|---|-----------|---------------------|--------|
| RC-01 | Shop name | Header: shop name in bold, double height | ☐ |
| RC-02 | Shop address | Below shop name | ☐ |
| RC-03 | Shop phone | Below address | ☐ |
| RC-04 | GST number | "GSTIN: XXXXXXXXXXXX" if configured | ☐ |
| RC-05 | Bill number | "Bill#: XXXX" | ☐ |
| RC-06 | Date & time | Formatted date/time of transaction | ☐ |
| RC-07 | Customer name | Customer name if selected | ☐ |
| RC-08 | Payment method | "Cash" / "Udhaar" / "UPI" etc. | ☐ |
| RC-09 | Item name | Each product name | ☐ |
| RC-10 | Item price × qty | "@₹XX × Y" format | ☐ |
| RC-11 | Item total | "= ₹ZZZ" | ☐ |
| RC-12 | Subtotal | Sum of items | ☐ |
| RC-13 | Tax (GST) | Tax amount if GST enabled | ☐ |
| RC-14 | Discount | Discount amount if applied | ☐ |
| RC-15 | Grand total | Final amount in bold | ☐ |
| RC-16 | Amount paid | Cash amount given | ☐ |
| RC-17 | Change returned | Change = paid - total | ☐ |
| RC-18 | Udhaar pending | "PAYMENT PENDING" for credit sales | ☐ |
| RC-19 | Custom footer | Footer text from settings | ☐ |
| RC-20 | Paper cut command | Auto-cut after receipt (thermal) | ☐ |

---

## 8. Hardware Settings UI Tests

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| HW-01 | Printer type selector | Settings > Hardware | Shows: System, Bluetooth, WiFi, USB options | ☐ |
| HW-02 | Platform-appropriate options | Open on Web | Hides Bluetooth/USB, shows System only | ☐ |
| HW-03 | Paper size toggle | Switch 58mm ↔ 80mm | Saves preference, next print uses new size | ☐ |
| HW-04 | Font size selector | Switch Small/Normal/Large | Saves preference, next print uses new font | ☐ |
| HW-05 | Receipt footer edit | Type custom footer text | Saved, appears on next receipt | ☐ |
| HW-06 | Auto-print toggle | Toggle on/off | Respects preference on next bill | ☐ |
| HW-07 | Test print button | Tap Test Print | Prints test page on selected printer | ☐ |
| HW-08 | Dark mode rendering | Enable dark mode, open Hardware settings | All UI elements visible and readable | ☐ |

---

## 9. Edge Cases & Error Handling

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| ERR-01 | Print with no printer configured | Try printing, no printer saved | Falls back to system print dialog | ☐ |
| ERR-02 | Print during connectivity loss | Disconnect WiFi/BT mid-print | Error toast, receipt not lost, can retry | ☐ |
| ERR-03 | Empty bill print | Try to print a ₹0 bill | Handles gracefully (skips or shows warning) | ☐ |
| ERR-04 | Very long receipt | Bill with 50+ items | Prints completely without cutoff | ☐ |
| ERR-05 | Special characters | Product with &, <, >, ", ' in name | Renders correctly, no escaping issues | ☐ |
| ERR-06 | Zero quantity item | Item with qty=0 on receipt | Skipped or shown as ₹0 | ☐ |
| ERR-07 | Printer paper out | Print when paper roll is empty | Error from printer SDK, user notified | ☐ |
| ERR-08 | Rapid consecutive prints | Complete 5 bills quickly with auto-print | All 5 receipts print in order | ☐ |
| ERR-09 | App backgrounded during print | Background app mid-print (Android) | Print completes, no data loss | ☐ |
| ERR-10 | Printer reconnect after failure | BT printer goes out of range, comes back | Auto-reconnects on next print attempt | ☐ |

---

## 10. Cross-Platform Matrix

| Test Area | Web ☐ | Windows ☐ | Android ☐ |
|-----------|-------|-----------|---------|
| System print dialog | ☐ | ☐ | ☐ |
| PDF receipt generation | ☐ | ☐ | ☐ |
| PDF preview before print | ☐ | ☐ | ☐ |
| WhatsApp bill share | ☐ | ☐ | ☐ |
| SMS bill share | ☐ | ☐ | ☐ |
| General share (share sheet) | ☐ | ☐ | ☐ |
| PDF download | ☐ | ☐ | ☐ |
| Auto-print after billing | ☐ | ☐ | ☐ |
| Bluetooth thermal | N/A | N/A | ☐ |
| WiFi thermal | N/A | ☐ | ☐ |
| USB thermal | N/A | ☐ | N/A |
| Hardware settings UI | ☐ | ☐ | ☐ |
| Dark mode all screens | ☐ | ☐ | ☐ |

---

## 11. Test Execution Summary

| Category | Total Tests | Passed | Failed | Blocked |
|----------|-------------|--------|--------|---------|
| Bluetooth (BT-01 to BT-20) | 20 | | | |
| WiFi (WF-01 to WF-12) | 12 | | | |
| USB (USB-01 to USB-07) | 7 | | | |
| System/PDF (SYS-01 to PDF-10) | 15 | | | |
| Bill Share (WA-01 to PDF-10) | 8 | | | |
| Receipt Content (RC-01 to RC-20) | 20 | | | |
| Hardware Settings (HW-01 to HW-08) | 8 | | | |
| Edge Cases (ERR-01 to ERR-10) | 10 | | | |
| **TOTAL** | **100** | | | |

---

## 12. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer | | | |
| QA Tester | | | |
| Product Owner | | | |

---

*Document generated: March 24, 2026*
*Total test cases: 100*
*Coverage: All 4 printer backends × 3 platforms × 6 receipt formats*
