# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: discovery.spec.ts >> two users can discover each other
- Location: playwright\flows\discovery.spec.ts:5:5

# Error details

```
TimeoutError: locator.waitFor: Timeout 15000ms exceeded.
Call log:
  - waiting for getByTestId('step-title').last() to be visible

```

# Page snapshot

```yaml
- generic [ref=e15]:
  - generic [ref=e16]:
    - generic [ref=e17]: BVisionRY Connect
    - generic [ref=e18]: Find the people who move your work forward
  - generic [ref=e19]:
    - generic [ref=e20]: Welcome
    - generic [ref=e21]:
      - button "Continue with Google" [ref=e23] [cursor=pointer]:
        - generic [ref=e24]: Continue with Google
      - button "Continue with Apple" [ref=e25] [cursor=pointer]:
        - generic [ref=e26]: Continue with Apple
    - generic [ref=e29]: or
    - generic [ref=e31]:
      - generic [ref=e32]: Email
      - textbox "you@example.com" [ref=e33]
    - button "Send magic link" [ref=e34] [cursor=pointer]:
      - generic [ref=e35]: Send magic link
    - generic [ref=e37] [cursor=pointer]: Forgot password?
    - generic [ref=e38]:
      - generic [ref=e39]: Don't have an account?
      - generic [ref=e41] [cursor=pointer]: Sign up
```

# Test source

```ts
  1  | import { Page } from '@playwright/test';
  2  | import { waitForMagicLink } from './mailpit';
  3  | 
  4  | type OnboardOpts = {
  5  |   email: string;
  6  |   name: string;
  7  |   handle: string;
  8  |   role: 'founder' | 'leader' | 'builder' | 'investor';
  9  |   goalType:
  10 |     | 'hire'
  11 |     | 'be_hired'
  12 |     | 'co_found'
  13 |     | 'invest'
  14 |     | 'take_investment'
  15 |     | 'advise'
  16 |     | 'find_advisor'
  17 |     | 'peer_connect';
  18 |   goalText: string;
  19 |   city: string;
  20 |   country: string;
  21 | };
  22 | 
  23 | /**
  24 |  * Drives the Phase-2 onboarding flow in the new order:
  25 |  *   1. Goal (type + text)
  26 |  *   2. Identity (name + handle)
  27 |  *   3. Roles
  28 |  *   4. About (city + country)
  29 |  */
  30 | export async function signUpAndOnboard(page: Page, opts: OnboardOpts) {
  31 |   await page.goto('/');
  32 |   await page.getByTestId('sign-in-email').fill(opts.email);
  33 |   await page.getByTestId('sign-in-submit').click();
  34 |   const magicLink = await waitForMagicLink(opts.email);
  35 |   await page.goto(magicLink);
  36 | 
> 37 |   await page.getByTestId('step-title').last().waitFor({ state: 'visible', timeout: 15_000 });
     |                                               ^ TimeoutError: locator.waitFor: Timeout 15000ms exceeded.
  38 | 
  39 |   // 1. Goal (free-form text — goal_type inferred / defaulted server-side)
  40 |   await page.getByTestId('goal-text').fill(opts.goalText);
  41 |   await page.getByTestId('goal-next').click();
  42 | 
  43 |   // 2. Identity
  44 |   await page.getByTestId('identity-name').fill(opts.name);
  45 |   await page.getByTestId('identity-handle').fill(opts.handle);
  46 |   await page.getByTestId('identity-next').click();
  47 | 
  48 |   // 3. Roles
  49 |   await page.getByTestId(`role-${opts.role}`).click();
  50 |   await page.getByTestId('roles-next').click();
  51 | 
  52 |   // 4. About
  53 |   await page.getByTestId('about-city').fill(opts.city);
  54 |   await page.getByTestId('about-country').fill(opts.country);
  55 |   await page.getByTestId('about-finish').click();
  56 | 
  57 |   await page.getByTestId('home-avatar').waitFor({ state: 'visible', timeout: 15_000 });
  58 | }
  59 | 
```