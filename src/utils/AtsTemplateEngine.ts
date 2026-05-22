import Mustache from 'mustache';

const templates: Record<string, string> = {
  classic: `<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
@page { margin: 15mm; size: A4; }
@media print { .resume-container { transform: none !important; width: 210mm; } }
body { word-wrap: break-word; overflow-wrap: break-word; margin: 0; padding: 0; }
* { box-sizing: border-box; }
.resume-container { width: 794px; margin: 0 auto; transform-origin: top center; font-family: Arial, Helvetica, sans-serif; background: #fff; color: #111; font-size: 11pt; line-height: 1.45; padding: 30px; }
.header { text-align: center; border-bottom: 2.5px solid #000; padding-bottom: 12px; margin-bottom: 18px; }
.name { font-size: 28pt; font-weight: bold; text-transform: uppercase; letter-spacing: 3px; color: #000; margin-bottom: 6px; }
.contact-container { font-size: 10pt; color: #333; display: flex; justify-content: center; flex-wrap: wrap; gap: 12px; }
.contact-item { display: inline-block; }
.contact-item span { font-weight: bold; margin-right: 3px; }
.section { margin-bottom: 18px; page-break-inside: avoid; }
.section-title { font-size: 12.5pt; font-weight: bold; text-transform: uppercase; letter-spacing: 2px; border-bottom: 1px solid #000; padding-bottom: 3px; margin-bottom: 10px; color: #000; page-break-after: avoid; }
.objective-text { font-size: 11pt; text-align: justify; color: #222; line-height: 1.5; }
.edu-item { margin-bottom: 10px; page-break-inside: avoid; }
.edu-row { display: flex; justify-content: space-between; align-items: baseline; }
.edu-inst { font-weight: bold; font-size: 11.5pt; color: #000; }
.edu-date, .edu-loc { font-size: 10pt; color: #555; }
.edu-degree { font-style: italic; font-size: 11pt; color: #222; }
.proj-item { margin-bottom: 12px; page-break-inside: avoid; }
.proj-title { font-weight: bold; font-size: 11.5pt; color: #000; }
.proj-link { font-weight: normal; font-size: 9pt; color: #555; }
.proj-desc { margin-left: 18px; margin-top: 3px; font-size: 10.5pt; color: #222; }
.proj-desc li { margin-bottom: 3px; text-align: justify; }
.skill-line { font-size: 11pt; margin-bottom: 5px; }
.skill-line strong { min-width: 140px; display: inline-block; }
.cert-list { margin-left: 18px; font-size: 11pt; }
.cert-list li { margin-bottom: 4px; }
</style></head><body>
<div class="resume-container">
<div class="header">
    <div class="name">{{fullName}}</div>
    <div class="contact-container">{{#contactItems}}<div class="contact-item"><span>{{{icon}}}</span> {{value}}</div>{{/contactItems}}</div>
</div>
{{#hasObjective}}<div class="section"><div class="section-title">Objective</div><div class="objective-text">{{objective}}</div></div>{{/hasObjective}}
{{#hasEducation}}<div class="section"><div class="section-title">Education</div>{{#educationList}}<div class="edu-item"><div class="edu-row"><span class="edu-inst">{{institution}}</span><span class="edu-date">{{year}}{{#hasPercentage}} | {{percentage}}{{/hasPercentage}}</span></div><div class="edu-row"><span class="edu-degree">{{degree}}</span><span class="edu-loc">{{location}}</span></div></div>{{/educationList}}</div>{{/hasEducation}}
{{#hasSkills}}<div class="section"><div class="section-title">Skills</div>{{#hasLanguages}}<div class="skill-line"><strong>Languages:</strong> {{languages}}</div>{{/hasLanguages}}{{#hasFrameworks}}<div class="skill-line"><strong>Frameworks:</strong> {{frameworks}}</div>{{/hasFrameworks}}{{#hasDevTools}}<div class="skill-line"><strong>Tools:</strong> {{devTools}}</div>{{/hasDevTools}}{{#hasCoursework}}<div class="skill-line"><strong>Coursework:</strong> {{courseworkText}}</div>{{/hasCoursework}}</div>{{/hasSkills}}
{{#hasProjects}}<div class="section"><div class="section-title">Projects</div>{{#projects}}<div class="proj-item"><div class="proj-title">{{title}}{{#hasLink}} <span class="proj-link">({{link}})</span>{{/hasLink}}</div>{{#hasBullets}}<ul class="proj-desc">{{#bullets}}<li>{{text}}.</li>{{/bullets}}</ul>{{/hasBullets}}</div>{{/projects}}</div>{{/hasProjects}}
{{#hasCertifications}}<div class="section"><div class="section-title">Certifications</div><ul class="cert-list">{{#certifications}}<li>{{#hasLink}}<a href="{{link}}" style="color:#1a73e8;text-decoration:none;">{{name}}</a>{{/hasLink}}{{^hasLink}}{{name}}{{/hasLink}}</li>{{/certifications}}</ul></div>{{/hasCertifications}}
</div>
</body></html>
`,
  // other templates omitted for brevity; you can add them similarly if needed
};

export function getHtml(cv: any) {
  const templateName = cv.templateId || 'classic';
  const rawTemplate = templates[templateName] || templates['classic'];

  const esc = (s: any) => {
    if (!s && s !== 0) return '';
    return String(s).replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  };

  const contactItems: any[] = [];
  if (cv.phone) contactItems.push({ icon: '&#9742;', value: esc(cv.phone) });
  if (cv.email) contactItems.push({ icon: '&#9993;', value: esc(cv.email) });
  if (cv.address) contactItems.push({ icon: '&#127968;', value: esc(cv.address) });
  if (cv.linkedIn) contactItems.push({ icon: '&#128279;', value: esc(cv.linkedIn) });
  if (cv.github) contactItems.push({ icon: '&#9999;', value: esc(cv.github) });

  const eduList = (cv.educationList || []).map((e: any) => ({
    institution: esc(e.institution),
    degree: esc(e.degree),
    year: esc(e.year),
    location: esc(e.location),
    percentage: esc(e.percentage),
    hasPercentage: !!e.percentage,
  }));

  const projList = (cv.projects || []).map((p: any) => {
    const bullets = (p.description || '').split(/\.|\n/).map((s: string) => s.trim()).filter(Boolean).map((text: string) => ({ text: esc(text) }));
    return {
      title: esc(p.title),
      link: esc(p.link),
      hasLink: !!p.link,
      bullets,
      hasBullets: bullets.length > 0,
    };
  });

  const certList = (cv.certifications || []).map((c: any) => ({
    name: esc(c.name),
    link: esc(c.link),
    hasLink: !!c.link,
  }));

  const ctx = {
    fullName: esc(cv.fullName),
    email: esc(cv.email),
    phone: esc(cv.phone),
    address: esc(cv.address),
    linkedIn: esc(cv.linkedIn),
    github: esc(cv.github),
    objective: esc(cv.objective),
    contactItems,
    hasContact: contactItems.length > 0,
    hasEducation: eduList.length > 0,
    educationList: eduList,
    hasProjects: projList.length > 0,
    projects: projList,
    languages: esc(cv.languages),
    hasLanguages: !!cv.languages,
    frameworks: esc(cv.frameworks),
    hasFrameworks: !!cv.frameworks,
    devTools: esc(cv.devTools),
    hasDevTools: !!cv.devTools,
    hasSkills: !!cv.languages || !!cv.frameworks || !!cv.devTools,
    hasCertifications: certList.length > 0,
    certifications: certList,
    objectiveExists: !!cv.objective,
  };

  try {
    return Mustache.render(rawTemplate, ctx);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('Mustache error:', err);
    return '<h1>Template Error</h1>';
  }
}

export default { getHtml };
