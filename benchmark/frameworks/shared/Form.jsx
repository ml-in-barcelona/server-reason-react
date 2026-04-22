// Port of benchmark/scenarios/Form.re
// Purpose: form-heavy page rendering

import React from "react";
import { cx } from "./cx.js";

const FormField = ({
  id,
  label,
  type = "text",
  required = true,
  placeholder = "",
  helpText,
  error,
}) => {
  let ariaDescribedby;
  if (helpText !== undefined) ariaDescribedby = `${id}-help`;
  else if (error !== undefined) ariaDescribedby = `${id}-error`;
  else ariaDescribedby = "<nop>";

  return (
    <div className="mb-4">
      <label htmlFor={id} className="block text-sm font-medium text-gray-700 mb-1">
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>
      <input
        type={type}
        id={id}
        name={id}
        required={required}
        placeholder={placeholder}
        className={cx([
          "w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors",
          error !== undefined ? "border-red-500 bg-red-50" : "border-gray-300",
        ])}
        aria-describedby={ariaDescribedby}
        aria-invalid={error !== undefined ? "true" : "false"}
      />
      {helpText !== undefined && (
        <p id={`${id}-help`} className="mt-1 text-sm text-gray-500">{helpText}</p>
      )}
      {error !== undefined && (
        <p id={`${id}-error`} className="mt-1 text-sm text-red-600 flex items-center gap-1">
          <span>⚠️</span>
          {error}
        </p>
      )}
    </div>
  );
};

const SelectField = ({ id, label, options, required = true }) => (
  <div className="mb-4">
    <label htmlFor={id} className="block text-sm font-medium text-gray-700 mb-1">
      {label}
      {required && <span className="text-red-500 ml-1">*</span>}
    </label>
    <select
      id={id}
      name={id}
      required={required}
      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
    >
      <option value="">Select an option...</option>
      {options.map(([value, optLabel], i) => (
        <option key={String(i)} value={value}>{optLabel}</option>
      ))}
    </select>
  </div>
);

const TextareaField = ({ id, label, rows = 4, required = true, placeholder = "" }) => (
  <div className="mb-4">
    <label htmlFor={id} className="block text-sm font-medium text-gray-700 mb-1">
      {label}
      {required && <span className="text-red-500 ml-1">*</span>}
    </label>
    <textarea
      id={id}
      name={id}
      rows={rows}
      required={required}
      placeholder={placeholder}
      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
    />
  </div>
);

const CheckboxField = ({ id, label, description }) => (
  <div className="mb-4">
    <div className="flex items-start gap-3">
      <input
        type="checkbox"
        id={id}
        name={id}
        className="mt-1 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
      />
      <div>
        <label htmlFor={id} className="text-sm font-medium text-gray-700">{label}</label>
        {description !== undefined && (
          <p className="text-sm text-gray-500">{description}</p>
        )}
      </div>
    </div>
  </div>
);

const RadioGroup = ({ name, label, options }) => (
  <fieldset className="mb-4">
    <legend className="block text-sm font-medium text-gray-700 mb-2">{label}</legend>
    <div className="space-y-2">
      {options.map(([value, optLabel, description], i) => (
        <div key={String(i)} className="flex items-start gap-3">
          <input
            type="radio"
            id={`${name}-${value}`}
            name={name}
            value={value}
            className="mt-1 h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
          />
          <div>
            <label htmlFor={`${name}-${value}`} className="text-sm font-medium text-gray-700">
              {optLabel}
            </label>
            {description !== undefined && description !== null && (
              <p className="text-sm text-gray-500">{description}</p>
            )}
          </div>
        </div>
      ))}
    </div>
  </fieldset>
);

const FormSection = ({ title, description, children }) => (
  <div className="mb-8 pb-8 border-b border-gray-200 last:border-0">
    <h3 className="text-lg font-semibold text-gray-900 mb-1">{title}</h3>
    {description !== undefined && (
      <p className="text-sm text-gray-500 mb-4">{description}</p>
    )}
    {children}
  </div>
);

const ProgressSteps = ({ steps, currentStep }) => (
  <nav className="mb-8">
    <ol className="flex items-center">
      {steps.map(([label], i) => {
        const isComplete = i < currentStep;
        const isCurrent = i === currentStep;
        return (
          <li key={String(i)} className="flex items-center">
            <div className="flex items-center">
              <span
                className={cx([
                  "w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium",
                  isComplete
                    ? "bg-blue-600 text-white"
                    : isCurrent
                      ? "border-2 border-blue-600 text-blue-600"
                      : "border-2 border-gray-300 text-gray-500",
                ])}
              >
                {isComplete ? "✓" : i + 1}
              </span>
              <span
                className={cx([
                  "ml-2 text-sm font-medium",
                  isCurrent ? "text-blue-600" : "text-gray-500",
                ])}
              >
                {label}
              </span>
            </div>
            {i < steps.length - 1 && (
              <div
                className={cx([
                  "w-16 h-0.5 mx-4",
                  isComplete ? "bg-blue-600" : "bg-gray-300",
                ])}
              />
            )}
          </li>
        );
      })}
    </ol>
  </nav>
);

const PersonalInfoForm = () => (
  <FormSection title="Personal Information" description="Please provide your basic personal details.">
    <div className="grid grid-cols-2 gap-4">
      <FormField id="firstName" label="First Name" placeholder="John" />
      <FormField id="lastName" label="Last Name" placeholder="Doe" />
    </div>
    <FormField id="email" label="Email Address" type="email" placeholder="john@example.com" />
    <FormField id="phone" label="Phone Number" type="tel" placeholder="+1 (555) 000-0000" />
    <FormField id="dob" label="Date of Birth" type="date" helpText="You must be at least 18 years old" />
    <SelectField
      id="gender"
      label="Gender"
      required={false}
      options={[
        ["male", "Male"],
        ["female", "Female"],
        ["other", "Other"],
        ["prefer-not", "Prefer not to say"],
      ]}
    />
  </FormSection>
);

const AddressForm = () => (
  <FormSection title="Address Information" description="Your residential address for correspondence.">
    <FormField id="address1" label="Address Line 1" placeholder="123 Main Street" />
    <FormField id="address2" label="Address Line 2" required={false} placeholder="Apt 4B" />
    <div className="grid grid-cols-2 gap-4">
      <FormField id="city" label="City" placeholder="New York" />
      <FormField id="state" label="State/Province" placeholder="NY" />
    </div>
    <div className="grid grid-cols-2 gap-4">
      <FormField id="zip" label="ZIP/Postal Code" placeholder="10001" />
      <SelectField
        id="country"
        label="Country"
        options={[
          ["us", "United States"],
          ["ca", "Canada"],
          ["uk", "United Kingdom"],
          ["de", "Germany"],
          ["fr", "France"],
          ["jp", "Japan"],
          ["au", "Australia"],
        ]}
      />
    </div>
  </FormSection>
);

const EmploymentForm = () => (
  <FormSection title="Employment Information" description="Tell us about your current employment.">
    <RadioGroup
      name="employmentStatus"
      label="Employment Status"
      options={[
        ["employed", "Employed", "Currently working full-time or part-time"],
        ["self-employed", "Self-Employed", "Running your own business"],
        ["unemployed", "Unemployed", "Currently seeking employment"],
        ["student", "Student", "Full-time student"],
        ["retired", "Retired", null],
      ]}
    />
    <FormField id="employer" label="Employer Name" required={false} placeholder="Company Inc." />
    <FormField id="jobTitle" label="Job Title" required={false} placeholder="Software Engineer" />
    <SelectField
      id="industry"
      label="Industry"
      required={false}
      options={[
        ["tech", "Technology"],
        ["finance", "Finance"],
        ["healthcare", "Healthcare"],
        ["education", "Education"],
        ["retail", "Retail"],
        ["manufacturing", "Manufacturing"],
        ["other", "Other"],
      ]}
    />
    <FormField
      id="income"
      label="Annual Income"
      type="number"
      required={false}
      placeholder="50000"
      helpText="This information helps us provide better recommendations"
    />
  </FormSection>
);

const PreferencesForm = () => (
  <FormSection title="Preferences" description="Customize your experience.">
    <SelectField
      id="language"
      label="Preferred Language"
      options={[
        ["en", "English"],
        ["es", "Spanish"],
        ["fr", "French"],
        ["de", "German"],
        ["zh", "Chinese"],
        ["ja", "Japanese"],
      ]}
    />
    <SelectField
      id="timezone"
      label="Timezone"
      options={[
        ["pst", "Pacific Time (PT)"],
        ["mst", "Mountain Time (MT)"],
        ["cst", "Central Time (CT)"],
        ["est", "Eastern Time (ET)"],
        ["utc", "UTC"],
        ["gmt", "GMT"],
      ]}
    />
    <RadioGroup
      name="theme"
      label="Theme Preference"
      options={[
        ["light", "Light", "Best for daytime use"],
        ["dark", "Dark", "Easier on the eyes at night"],
        ["auto", "System", "Follows your device settings"],
      ]}
    />
    <div className="mt-6">
      <h4 className="text-sm font-medium text-gray-700 mb-3">Notification Preferences</h4>
      <CheckboxField id="notifyEmail" label="Email notifications" description="Receive updates via email" />
      <CheckboxField id="notifySms" label="SMS notifications" description="Receive text message alerts" />
      <CheckboxField id="notifyPush" label="Push notifications" description="Receive browser notifications" />
      <CheckboxField id="newsletter" label="Newsletter subscription" description="Weekly digest of updates and tips" />
    </div>
  </FormSection>
);

const AdditionalInfoForm = () => (
  <FormSection title="Additional Information">
    <TextareaField
      id="bio"
      label="Bio"
      rows={4}
      required={false}
      placeholder="Tell us a bit about yourself..."
    />
    <FormField id="website" label="Website" type="url" required={false} placeholder="https://example.com" />
    <FormField
      id="linkedin"
      label="LinkedIn Profile"
      type="url"
      required={false}
      placeholder="https://linkedin.com/in/username"
    />
    <FormField id="twitter" label="Twitter Handle" required={false} placeholder="@username" />
    <TextareaField
      id="referral"
      label="How did you hear about us?"
      rows={2}
      required={false}
      placeholder="Friend, social media, search engine, etc."
    />
  </FormSection>
);

const TermsForm = () => (
  <FormSection title="Terms and Conditions">
    <div className="bg-gray-50 rounded-lg p-4 mb-4 h-48 overflow-y-auto text-sm text-gray-600">
      <p className="mb-2">By using our services, you agree to these terms. Please read them carefully.</p>
      <p className="mb-2">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
      </p>
      <p className="mb-2">
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
      </p>
      <p>
        Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.
      </p>
    </div>
    <CheckboxField id="acceptTerms" label="I accept the Terms and Conditions" description="You must accept to continue" />
    <CheckboxField id="acceptPrivacy" label="I accept the Privacy Policy" description="Your data will be handled according to our privacy policy" />
    <CheckboxField id="acceptMarketing" label="I agree to receive marketing communications" description="Optional - you can unsubscribe at any time" />
  </FormSection>
);

const formSteps = [
  ["Personal", "Basic info"],
  ["Address", "Location"],
  ["Employment", "Work details"],
  ["Preferences", "Settings"],
  ["Additional", "Extra info"],
  ["Review", "Confirm"],
];

export const Form = () => (
  <html lang="en">
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>Registration Form</title>
    </head>
    <body className="bg-gray-100 min-h-screen py-12">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Create Your Account</h1>
          <p className="text-gray-600">Complete the form below to get started</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
          <ProgressSteps steps={formSteps} currentStep={2} />
        </div>
        <form className="bg-white rounded-xl shadow-sm p-8">
          <PersonalInfoForm />
          <AddressForm />
          <EmploymentForm />
          <PreferencesForm />
          <AdditionalInfoForm />
          <TermsForm />
          <div className="flex items-center justify-between pt-6 border-t border-gray-200">
            <button
              type="button"
              className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
            >
              ← Previous
            </button>
            <div className="flex gap-4">
              <button
                type="button"
                className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Save Draft
              </button>
              <button
                type="submit"
                className="px-8 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700"
              >
                Continue →
              </button>
            </div>
          </div>
        </form>
        <div className="mt-6 text-center text-sm text-gray-500">
          <p>
            Need help?{" "}
            <a href="#" className="text-blue-600 hover:underline">Contact Support</a>
          </p>
        </div>
      </div>
    </body>
  </html>
);
