#!/usr/bin/env node

/* eslint-disable @typescript-eslint/no-var-requires */
const fs = require("fs");
const path = require("path");

// Minimal PDF structure
const pdfContent = `%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Count 1
/Kids [3 0 R]
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/Resources <<
/Font <<
/F1 4 0 R
>>
>>
/MediaBox [0 0 612 792]
/Contents 5 0 R
>>
endobj
4 0 obj
<<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
endobj
5 0 obj
<<
/Length 178
>>
stream
BT
/F1 24 Tf
72 720 Td
(Test Document for Karakeep) Tj
0 -30 Td
/F1 16 Tf
(This is a test PDF for E2E testing.) Tj
0 -20 Td
(It verifies PDF sharing functionality.) Tj
ET
endstream
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000262 00000 n 
0000000341 00000 n 
trailer
<<
/Size 6
/Root 1 0 R
>>
startxref
570
%%EOF`;

// Create the PDF file
const outputPath = path.join(__dirname, "test-document.pdf");
fs.writeFileSync(outputPath, pdfContent);

console.log(`✅ Test PDF created at: ${outputPath}`);
console.log("Size:", fs.statSync(outputPath).size, "bytes");
