# Webmapr centred login — visual QA

Source visual truth: `/home/danny/.codex/attachments/5df76ac9-32d2-4749-8995-ca538d9c6474/codex-clipboard-89e66e26-812b-4c02-ad92-1962f4504829.png`.

Implementation: https://app.webmapr.com/login. This supplied screenshot supersedes the earlier split-screen selection.

Source and desktop implementation: 1487 × 1058 pixels, viewport 1487 × 1058 CSS px, deviceScaleFactor 1. No density normalization. State: empty login form, light surface, no validation errors, unfocused fields. Additional responsive captures: 1280 × 800, 834 × 1194, 390 × 844, and 320 × 667.

## Comparison history

Initial full comparison: `/tmp/webmapr-login-comparison-1.png`, source left and implementation right. Focused form comparison: `/tmp/webmapr-login-focus-1.png`. Browser implementation: `/tmp/webmapr-centered-login-desktop.png`.

- P2: password placeholder from source missing. Added “Enter your password”.
- P2: headline slightly narrow/light and checkbox too small/light. Increased headline to 64px/750 and checkbox to 24px with a stronger border; tightened subtitle spacing.
- P2: at 1280 × 800, orange tagline crossed the orange ribbon. Moved the short-screen tagline higher.
- P2: mobile copyright crossed the ribbon. Moved mobile artwork above the footer.

## Required fidelity surfaces

- Fonts/typography: established Instrument Sans matches the geometric source; adjusted display weight/size and subtitle spacing. Brand logo reused from the supplied brand work. Controls remain readable; heading stays on one line at desktop and mobile.
- Spacing/layout: centred 453px form; desktop logo at x72/y40, headline near y183, form near y332. Account-access label at upper right, tagline lower left, copyright bottom left. Responsive layout keeps artwork clear of form controls.
- Colors/tokens: warm nearwhite ground, orange artwork, charcoal text. Action and small links use slightly deeper orange than the mock to retain legibility; action uses a solid fill within the existing component system.
- Image quality/assets: genuine raster background extracted with built-in Image Gen; supplied brand logo reused. No code-drawn artwork. All interface text and controls remain real HTML. Asset: `/home/danny/laravel-production-docker/app/public/images/webmapr-login-waves.png`, 1486 × 1058 PNG, scaled less than 0.1% horizontally at target viewport.
- Copy/content: screenshot headline, helper, email/password labels and hints, remember-me, recovery, login, passkey, account-access, tagline, copyright reproduced. Current-year copyright retained.

Image Gen prompt: “Remove all foreground UI, text, logo, buttons, fields, icons and copyright. Fill removed regions with uninterrupted warm nearwhite #fdfbf7. Preserve bottom orange ribbons, peach waves, curved connection lines and circular dots at the same positions, colors and geometry. No text, logo or watermark.” Built-in reference-edit mode.

## Verification

- Production build and targeted ESLint passed.
- Authentication, password reset, and two-factor feature tests: 13 passed, 33 assertions.
- Initial live browser tests: password reveal/hide, remember-me, recovery navigation; five viewports without horizontal overflow or JavaScript errors.
- Final live browser interactions passed: password reveal/hide, remember-me, invalid-password feedback, successful administrator login, logout, and password recovery navigation. Passkey control is preserved; physical authenticator interaction was not available for this check.
- All five final viewports fit horizontally and keep form controls clear of the tagline and artwork. Dark system preference retains the intended light, legible login surface. No JavaScript page errors.
- Final full-view comparison: `/tmp/webmapr-login-comparison-final.png` (source left, revised implementation right). Final focused form comparison: `/tmp/webmapr-login-focus-final.png`. Both were opened and inspected together.
- Final implementation screenshot: `/tmp/webmapr-centered-login-desktop-final.png`. Post-fix laptop: `/tmp/webmapr-centered-login-laptop-final.png`; post-fix mobile: `/tmp/webmapr-centered-login-mobile-final.png`. Tablet/small/dark-preference/recovery captures use `/tmp/webmapr-centered-login-{tablet,small,dark-preference,recovery}-final.png` inside the PHP container.
- Post-fix visual review: password hint restored, headline scale/weight corrected, checkbox clearly visible, laptop tagline above ribbons, mobile footer below artwork. No actionable P0/P1/P2 findings remain. Minor source font/brand raster differences and the accessible solid action fill are accepted P3 refinements.

## Implementation checklist

1. Completed post-fix full and focused visual comparison.
2. Completed responsive and authentication interaction verification.
3. Recorded final evidence; production login is running with the selected design.

## Follow-up polish

- P3: slight raster logo lettering and font metric differences from the generated reference are acceptable; retain the established production font and brand assets.

final result: passed
