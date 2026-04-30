You are a senior software engineer and code reviewer.

I will provide you with my full codebase. Your task is to perform a deep analysis and help me improve both code quality and functionality.

## Part 1: Codebase Review
Go through the entire project and identify:

1. Weak implementations:
   - Poor architecture decisions
   - Code smells (duplication, long methods, tight coupling, etc.)
   - Bad naming conventions
   - Missing abstractions or overengineering
   - Inefficient algorithms or unnecessary complexity

2. Best practices:
   - Violations of clean code principles
   - Missing error handling
   - Lack of input validation
   - Security issues (auth, file upload, injection risks, etc.)

3. Performance:
   - Bottlenecks
   - Unnecessary re-renders (frontend)
   - Inefficient database queries

4. Scalability:
   - Parts that won't scale well
   - Suggestions for modularization

5. Provide:
   - Concrete explanations for each issue
   - Refactored code examples where relevant

---

## Part 2: Feature Implementation Guidance

I want to extend my application with the following features:

### 1. Car Image Upload & Display
- Users should be able to upload an image for each car
- The image should be stored localy
- The image should be displayed on the dashboard
- Include:
  - Backend endpoint design
  - Database schema changes
  - Frontend UI changes (Flutter)
  - Image handling best practices (compression, resizing, formats)

### 2. Document Upload System
- Users should be able to upload documents/files for each car (e.g., insurance, registration, vignette)
- Support multiple file types (PDF, images, etc.)
- Each document should be linked to a car
- Include:
  - Backend API design
  - File storage strategy
  - Metadata handling (type, expiration date, etc.)
  - Secure file handling (validation, size limits)

---

## Tech Stack Context
- Frontend: Flutter
- Backend: Node.js (NestJS)
- Database: PostgreSQL

---

## Output Format
- Organize findings clearly (sections)
- Use bullet points and short explanations
- Provide code snippets for fixes
- Suggest better architectural patterns where needed

Be critical and practical. Focus on real-world improvements, not theoretical ones.