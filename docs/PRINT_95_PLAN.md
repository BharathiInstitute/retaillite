 # RetailLite — Print Support 95% Readiness Plan

> **Current Score: ~100%** ✅ (All phases complete)
> **Platforms: Web, Windows, Android**
> **Date: March 24, 2026**
> **Completed: All 7 phases implemented (Phases 1-3: backends, Phases 4-7: settings 100%)**

---

## 1. Current State (What's Done ✅)

### Printer Backends — 6/6 Complete

| Backend | Protocol | Platforms | Status |
|---------|----------|-----------|--------|
| Bluetooth Thermal | ESC/POS via BT Classic | Android | ✅ 100% |
| WiFi/Network Thermal | ESC/POS over TCP:9100 | Windows, Android | ✅ 100% |
| USB Thermal | Windows Spooler + ESC/POS | Windows | ✅ 100% |
| System Printer | Platform print dialog (PDF) | Web, Windows, Android | ✅ 100% |
| Sunmi Built-in | Sunmi SDK (sunmi_printer_plus) | Android (Sunmi POS) | ✅ 100% |
| Web Bluetooth | Chrome Web Bluetooth API | Web (Chrome/Edge) | ✅ 100% |

### Receipt Formats — 6/6 Complete

| Format | Details | Status |
|--------|---------|--------|
| ESC/POS 58mm | 32 chars/line thermal | ✅ |
| ESC/POS 80mm | 48 chars/line thermal | ✅ |
| PDF Roll 57mm | 80.76 × 203.2mm | ✅ |
| PDF Roll 80mm | 110.5 × 203.2mm | ✅ |
| PDF A5 Invoice | 148 × 210mm (share format) | ✅ |
| Plain Text | WhatsApp/SMS share | ✅ |

### Features — 17/17 Complete

- ✅ Auto-print after billing
- ✅ Print preview option
- ✅ Custom receipt footer
- ✅ Shop logo on PDF receipt
- ✅ QR code on receipt
- ✅ Font size options (Small/Normal/Large)
- ✅ Paper size selector (58mm/80mm)
- ✅ WhatsApp bill share (direct + general)
- ✅ SMS bill share
- ✅ PDF download/share
- ✅ Test print button
- ✅ Saved printer auto-reconnect
- ✅ UTF-8 encoding (Hindi, ₹ symbol)
- ✅ Hardware settings UI (full configuration)
- ✅ Sunmi built-in printer support (Phase 1)
- ✅ Cash drawer kick command (Phase 2)
- ✅ Web Bluetooth printing (Phase 3)

---

## 2. Gap Analysis (What's Missing)

| Gap | Impact | Current Market Need |
|-----|--------|---------------------|
| **Sunmi built-in printer** | HIGH — #1 Android POS device in India (60%+ market) | Critical for Android retail |
| **Cash drawer kick** | MEDIUM — Expected by retailers using cash registers | Standard in POS systems |
| **Web Bluetooth API** | LOW-MEDIUM — Chrome-only, limited but growing | Nice-to-have |
| **Web USB API** | LOW — Very limited browser support | Future-proof |
| **Multi-printer routing** | LOW — Retail doesn't need KOT printing | Restaurant-only |
| **Star Micronics SDK** | LOW — Rare in India, expensive | Enterprise only |

---

## 3. Implementation Plan — Phases

### Phase 1: Sunmi Built-in Printer (85% → 91%) ✅ COMPLETE

**Why**: Sunmi V2/V2 Pro/T2 are the most popular Android POS terminals in India. They have a built-in thermal printer accessed via the Sunmi SDK — not Bluetooth or WiFi.

**Package**: `sunmi_printer_plus: ^4.1.1` (pub.dev)

**Tasks**:

| # | Task | File | Effort |
|---|------|------|--------|
| 1.1 | Add `sunmi_printer_plus: ^2.2.0` to pubspec.yaml | `pubspec.yaml` | 5 min |
| 1.2 | Create `SunmiPrinterService` class | `lib/core/services/sunmi_printer_service.dart` | 2-3 hrs |
| 1.3 | Add `PrinterTypeOption.sunmi` enum value | `lib/features/settings/providers/settings_provider.dart` | 15 min |
| 1.4 | Add Sunmi option to Hardware Settings UI | `lib/features/settings/screens/hardware_settings_screen.dart` | 1 hr |
| 1.5 | Wire Sunmi into print dispatch in payment_modal | `lib/features/billing/widgets/payment_modal.dart` | 30 min |
| 1.6 | Auto-detect Sunmi device at startup | `lib/core/services/sunmi_printer_service.dart` | 30 min |
| 1.7 | Unit tests for Sunmi service | `test/services/sunmi_printer_service_test.dart` | 1 hr |

**SunmiPrinterService API**:
```dart
class SunmiPrinterService {
  static Future<bool> get isAvailable;         // Check if running on Sunmi device
  static Future<bool> get isReady;             // Printer paper loaded, not overheated
  static Future<void> printReceipt({...});     // Use Sunmi SDK formatting
  static Future<void> printTestPage();         // Test page
  static Future<PrinterStatus> getStatus();    // Paper, temperature, error state
}
```

**Estimated Effort**: 1 day

---

### Phase 2: Cash Drawer Kick Command (91% → 93%) ✅ COMPLETE

**Why**: Retailers with cash drawers expect automatic open on payment. This is a standard ESC/POS feature.

**ESC/POS Command**: `0x1B, 0x70, 0x00, 0x19, 0xFA` (pulse pin 2, 25ms on, 250ms off)

**Tasks**:

| # | Task | File | Effort |
|---|------|------|--------|
| 2.1 | Add `cashDrawerKick()` to `EscPosBuilder` | `lib/core/services/thermal_printer_service.dart` | 15 min |
| 2.2 | Add "Open Cash Drawer" toggle to Hardware Settings | `hardware_settings_screen.dart` | 30 min |
| 2.3 | Add `openCashDrawer` to `PrinterStorage` prefs | `settings_provider.dart` | 15 min |
| 2.4 | Append kick command after receipt in all thermal backends | `thermal_printer_service.dart` | 30 min |
| 2.5 | Add manual "Open Drawer" button to POS toolbar | `pos_web_screen.dart` | 30 min |
| 2.6 | Test with BT, WiFi, USB backends | Manual testing | 30 min |

**Estimated Effort**: 3 hours

---

### Phase 3: Web Bluetooth Printing (93% → 95%) ✅ COMPLETE

**Why**: Allows Chrome (web) users to print directly to Bluetooth thermal printers without installing any app.

**API**: Web Bluetooth API (`navigator.bluetooth.requestDevice()`)

**Tasks**:

| # | Task | File | Effort |
|---|------|------|--------|
| 3.1 | Create `WebBluetoothPrinterService` | `lib/core/services/web_bluetooth_printer_service.dart` | 3-4 hrs |
| 3.2 | Add JS interop for Web Bluetooth API | `web/` or `lib/core/services/` | 1 hr |
| 3.3 | Add `PrinterTypeOption.webBluetooth` enum | `settings_provider.dart` | 15 min |
| 3.4 | Add Web BT option to Hardware Settings (web only) | `hardware_settings_screen.dart` | 1 hr |
| 3.5 | Wire into print dispatch | `payment_modal.dart` | 30 min |
| 3.6 | Handle Chrome-only limitation gracefully | UI warning for non-Chrome browsers | 30 min |
| 3.7 | Test on Chrome desktop + Android Chrome | Manual testing | 1 hr |

**Limitations**:
- Chrome/Edge only (no Firefox/Safari)
- Requires HTTPS or localhost
- User must pair device each session (no auto-reconnect in Web BT)

**Estimated Effort**: 1.5 days

---

## 4. Timeline Summary

| Phase | Feature | Score After | Effort | Priority | Status |
|-------|---------|-------------|--------|----------|--------|
| Phase 1 | Sunmi Built-in Printer | 91% | 1 day | P1 — Critical | ✅ Done |
| Phase 2 | Cash Drawer Kick | 93% | 3 hours | P1 — Easy win | ✅ Done |
| Phase 3 | Web Bluetooth Printing | 95% | 1.5 days | P2 — Nice-to-have | ✅ Done |
| Phase 4 | Fix Broken + Print Copies | 96% | 3 hours | P1 — Critical | ✅ Done |
| Phase 5 | UPI QR Code on Receipt | 98% | 4.5 hours | P1 — Critical | ✅ Done |
| Phase 6 | GST Tax Breakdown | 99% | 3.5 hours | P1 — Legal req | ✅ Done |
| Phase 7 | Receipt Customization | 100% | 5.5 hours | P2 — Polish | ✅ Done |
| **Total** | | **100%** | **~5.5 days** | | **✅ Complete** |

---

## 5. Platform Coverage After 95% Plan

| Feature | Web | Windows | Android |
|---------|-----|---------|---------|
| Bluetooth Thermal | ✅ (Phase 3) | ❌ | ✅ |
| WiFi Thermal (TCP) | ❌ | ✅ | ✅ |
| USB Thermal | ❌ | ✅ | ❌ |
| Sunmi Built-in | ❌ | ❌ | ✅ (Phase 1) |
| System Print Dialog | ✅ | ✅ | ✅ |
| PDF Generation | ✅ | ✅ | ✅ |
| Cash Drawer Kick | ✅ (Phase 3) | ✅ (Phase 2) | ✅ (Phase 2) |
| WhatsApp/SMS Share | ✅ | ✅ | ✅ |

---

## 6. Print Settings 100% Plan (95% → 100%)

### Current Print Settings Inventory (11 settings — 83% coverage)

| # | Setting | Type | Default | Storage Key | UI | Status |
|---|---------|------|---------|-------------|-----|--------|
| 1 | Paper Size | int (0/1) | 1 (80mm) | `printer_paper_size` | ✅ SegmentedButton | ✅ Working |
| 2 | Font Size | int (0/1/2) | 1 (Normal) | `printer_font_size` | ✅ SegmentedButton | ✅ Working |
| 3 | Custom Width | int | 0 (auto) | `printer_custom_width` | ❌ No UI | ⚠️ Stored but hidden |
| 4 | Printer Type | enum (6) | system | `printer_type` | ✅ Radio buttons | ✅ Working |
| 5 | Auto-Print | bool | false | `printer_auto_print` | ✅ Toggle | ✅ Working |
| 6 | Cash Drawer | bool | false | `printer_open_cash_drawer` | ✅ Toggle | ✅ Working |
| 7 | Receipt Footer | String | "" | `printer_receipt_footer` | ✅ TextField | ✅ Working |
| 8 | Printer Name | String? | null | `printer_name` | ✅ Display only | ✅ Working |
| 9 | Printer Address | String? | null | `printer_address` | ✅ Display only | ✅ Working |
| 10 | WiFi IP + Port | String + int | —/9100 | `printer_wifi_ip/port` | ✅ TextFields | ✅ Working |
| 11 | USB Printer | String | "" | `printer_usb_name` | ✅ Dropdown | ✅ Working |
| 12 | Barcode Prefix | String | "" | ❌ Not persisted | ✅ TextField | ❌ Broken |
| 13 | Barcode Suffix | String | "" | ❌ Not persisted | ✅ TextField | ❌ Broken |

---

### Phase 4: Fix Broken Settings + Print Copies (95% → 96%) ✅ COMPLETE

| # | Task | File(s) | Effort | Details |
|---|------|---------|--------|---------|
| 4.1 | Persist barcode prefix/suffix | `offline_storage_service.dart` + `hardware_settings_screen.dart` | 30 min | Add `_barcodePrefixKey`/`_barcodeSuffixKey`, load in initState, save onChanged |
| 4.2 | Add Custom Width slider to UI | `hardware_settings_screen.dart` | 30 min | Slider 0-52 (0=auto), shown under Paper Size section |
| 4.3 | Add Print Copies setting | `settings_provider.dart` + `offline_storage_service.dart` | 30 min | `printCopies` int (1-3), default 1, key `printer_print_copies` |
| 4.4 | Add Copies UI to Receipt Settings | `hardware_settings_screen.dart` | 30 min | SegmentedButton: 1 / 2 / 3 copies |
| 4.5 | Wire copies into print dispatch | `payment_modal.dart` + `pos_web_widgets.dart` | 30 min | Loop `for (var i = 0; i < copies; i++)` around print call |
| 4.6 | Update tests | `test/providers/settings_provider_test.dart` | 30 min | Test new fields |

---

### Phase 5: UPI QR Code on Receipt (96% → 98%) ✅ COMPLETE

| # | Task | File(s) | Effort | Details |
|---|------|---------|--------|---------|
| 5.1 | Add `showQrOnReceipt` bool setting | `settings_provider.dart` + `offline_storage_service.dart` | 15 min | Default false, key `printer_show_qr` |
| 5.2 | Add QR toggle to Receipt Settings UI | `hardware_settings_screen.dart` | 15 min | Toggle: "Show UPI QR on receipt" (visible only if user has upiId) |
| 5.3 | Generate UPI QR in PDF receipt | `receipt_service.dart` | 1.5 hrs | Use `qr_flutter` (already in pubspec) → `upi://pay?pa={upiId}&pn={shopName}&am={total}` → render as pw.BarcodeWidget in PDF |
| 5.4 | Generate UPI QR in ESC/POS receipt | `thermal_printer_service.dart` | 2 hrs | ESC/POS image mode (GS v 0) — render QR to bitmap, convert to ESC/POS raster. Pass `upiId` to `buildReceipt()` |
| 5.5 | Pass upiId through print dispatch | `payment_modal.dart` + `pos_web_widgets.dart` | 30 min | Add `upiId` param to all `printReceipt()` calls |
| 5.6 | Update tests | `test/services/receipt_content_test.dart` | 30 min | Test QR bytes present when upiId provided |

---

### Phase 6: GST Tax Breakdown on Receipt (98% → 99%) ✅ COMPLETE

| # | Task | File(s) | Effort | Details |
|---|------|---------|--------|---------|
| 6.1 | Add `showGstBreakdown` bool setting | `settings_provider.dart` + `offline_storage_service.dart` | 15 min | Default false, key `printer_show_gst_breakdown` |
| 6.2 | Add GST toggle to Receipt Settings UI | `hardware_settings_screen.dart` | 15 min | Toggle: "Show GST breakdown" (visible only if user has gstNumber) |
| 6.3 | Calculate CGST/SGST from total | `thermal_printer_service.dart` | 30 min | Compute: `taxableAmount = total / 1.18`, `gst = total - taxableAmount`, `cgst = sgst = gst / 2`. Use shop's tax rate from settings |
| 6.4 | Add GST section to ESC/POS receipt | `thermal_printer_service.dart` | 1 hr | After items, before total: `Taxable Amount`, `CGST @9%`, `SGST @9%`, separator line |
| 6.5 | Add GST section to PDF receipt | `receipt_service.dart` | 1 hr | Same section in PDF layout |
| 6.6 | Pass `taxRate` + `showGstBreakdown` to builders | `payment_modal.dart` + `pos_web_widgets.dart` | 30 min | Thread through print dispatch |
| 6.7 | Update tests | `test/services/receipt_content_test.dart` | 30 min | Test GST lines present when enabled |

---

### Phase 7: Receipt Customization Polish (99% → 100%) ✅ COMPLETE

| # | Task | File(s) | Effort | Details |
|---|------|---------|--------|---------|
| 7.1 | Add `receiptLanguage` setting | `settings_provider.dart` + `offline_storage_service.dart` | 15 min | Enum: `english` / `hindi`, default english, key `printer_receipt_language` |
| 7.2 | Add Receipt Language selector UI | `hardware_settings_screen.dart` | 30 min | SegmentedButton: English / हिन्दी |
| 7.3 | Localize receipt strings | `thermal_printer_service.dart` + `receipt_service.dart` | 1.5 hrs | Map<String, Map>: `{'Bill No': 'बिल नं', 'Item': 'सामान', 'Qty': 'मात्रा', 'Amount': 'राशि', 'Total': 'कुल', 'Thank You': 'धन्यवाद', ...}` |
| 7.4 | Add `showLogoOnThermal` bool setting | `settings_provider.dart` + `offline_storage_service.dart` | 15 min | Default false, key `printer_show_logo_thermal` |
| 7.5 | Add Logo toggle for thermal | `hardware_settings_screen.dart` | 15 min | Toggle: "Print shop logo" (thermal only, visible when logo exists) |
| 7.6 | Implement logo on ESC/POS | `thermal_printer_service.dart` | 2 hrs | Load logo → resize to printer width → convert to 1-bit bitmap → GS v 0 raster print |
| 7.7 | Add `cutMode` setting | `settings_provider.dart` + `offline_storage_service.dart` | 15 min | Enum: `fullCut` / `partialCut`, default fullCut, key `printer_cut_mode` |
| 7.8 | Add Cut Mode selector UI | `hardware_settings_screen.dart` | 15 min | SegmentedButton: Full Cut / Partial Cut |
| 7.9 | Wire cut mode into ESC/POS | `thermal_printer_service.dart` | 15 min | Full: `[0x1D, 0x56, 0x00]`, Partial: `[0x1D, 0x56, 0x01]` |
| 7.10 | Update tests | `test/providers/settings_provider_test.dart` + receipt tests | 30 min | All new fields |

---

### New Settings Summary (Phases 4-7)

| # | New Setting | Type | Default | Storage Key | Phase |
|---|------------|------|---------|-------------|-------|
| 1 | Print Copies | int (1-3) | 1 | `printer_print_copies` | 4 |
| 2 | Show UPI QR | bool | false | `printer_show_qr` | 5 |
| 3 | Show GST Breakdown | bool | false | `printer_show_gst_breakdown` | 6 |
| 4 | Receipt Language | enum | english | `printer_receipt_language` | 7 |
| 5 | Show Logo (Thermal) | bool | false | `printer_show_logo_thermal` | 7 |
| 6 | Cut Mode | enum | fullCut | `printer_cut_mode` | 7 |

### Fixed Settings (Phase 4)

| # | Fix | Issue |
|---|-----|-------|
| 1 | Barcode prefix persistence | UI exists, not saved to storage |
| 2 | Barcode suffix persistence | UI exists, not saved to storage |
| 3 | Custom Width UI | Stored but no UI control |

---

### Timeline Summary (95% → 100%)

| Phase | Feature | Score After | Effort | Priority | Status |
|-------|---------|-------------|--------|----------|--------|
| Phase 4 | Fix Broken + Print Copies | 96% | 3 hours | P1 — Critical | ✅ Done |
| Phase 5 | UPI QR Code on Receipt | 98% | 4.5 hours | P1 — Critical (India UPI) | ✅ Done |
| Phase 6 | GST Tax Breakdown | 99% | 3.5 hours | P1 — Legal requirement | ✅ Done |
| Phase 7 | Receipt Customization | 100% | 5.5 hours | P2 — Polish | ✅ Done |
| **Total** | | **100%** | **~16.5 hours** | | **✅ Complete** |

### Final Print Settings Count: 19 settings (currently 13 → add 6 new, fix 3 broken)

| Category | Before | After | Coverage |
|----------|--------|-------|----------|
| Paper & Format | 3 settings | 3 settings | 100% |
| Font & Layout | 1 setting | 3 settings (+copies, +cut mode) | 100% |
| Receipt Content | 1 setting (footer) | 5 settings (+QR, +GST, +language, +logo) | 100% |
| Device & Connection | 6 settings | 6 settings | 100% |
| Print Workflow | 2 settings | 2 settings | 100% |
| Scanner | 2 broken | 2 fixed | 100% |
| **Total** | **13 (83%)** | **19 (100%)** | **100%** |
- `lib/core/services/thermal_printer_service.dart` — Cash drawer command
- `lib/features/billing/screens/pos_web_screen.dart` — Manual drawer button

### Files Modified in Phases 4-7
- `lib/features/settings/providers/settings_provider.dart` — 6 new fields in PrinterState
- `lib/core/services/offline_storage_service.dart` — 8 new storage keys
- `lib/features/settings/screens/hardware_settings_screen.dart` — 6 new UI controls
- `lib/core/services/thermal_printer_service.dart` — QR image, GST section, logo, cut mode, receipt language
- `lib/core/services/receipt_service.dart` — QR widget, GST section, receipt language
- `lib/features/billing/widgets/payment_modal.dart` — Pass copies, upiId, taxRate, language
- `lib/features/billing/screens/pos_web_widgets.dart` — Same dispatch updates
- `test/providers/settings_provider_test.dart` — New field tests
- `test/services/receipt_content_test.dart` — QR, GST, language tests

---

*Document generated: March 24, 2026*
