const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.qq.com',
  port: 465,
  secure: true,
  auth: {
    user: '3281607568@qq.com',
    pass: process.env.QQ_SMTP_AUTH_CODE || '',
  },
});

async function sendMail(to, subject, html) {
  await transporter.sendMail({
    from: '"心晴日记" <3281607568@qq.com>',
    to,
    subject,
    html,
  });
}

/** 发邮箱验证码 */
async function sendEmailCode(email, code) {
  await sendMail(email, '心晴日记 - 邮箱验证码',
    `<div style="max-width:480px;margin:0 auto;padding:24px;font-family:Arial,sans-serif;background:#fdfaf5;border-radius:16px">
      <h2 style="color:#b8782c;margin:0 0 16px">心晴日记</h2>
      <p style="font-size:16px;color:#2f2118;line-height:1.6">你的验证码是：</p>
      <div style="background:#fffcf7;padding:20px;text-align:center;border-radius:12px;margin:16px 0">
        <span style="font-size:36px;font-weight:bold;color:#b8782c;letter-spacing:8px">${code}</span>
      </div>
      <p style="font-size:13px;color:#6f6256;line-height:1.6">验证码 5 分钟内有效。如非本人操作，请忽略本邮件。</p>
      <hr style="border:none;border-top:1px solid #EAD9C5;margin:20px 0">
      <p style="font-size:11px;color:#9a8a7d">心晴日记 — 记录天气，也记录你</p>
    </div>`
  );
}

/** 天气反馈邮件 */
async function sendWeatherFeedback(data) {
  await sendMail('3281607568@qq.com', `天气反馈 - ${data.type}`,
    `<div style="max-width:480px;margin:0 auto;padding:24px;font-family:Arial,sans-serif;background:#fdfaf5;border-radius:16px">
      <h2 style="color:#b8782c;margin:0 0 16px">天气反馈</h2>
      <table style="width:100%;border-collapse:collapse">
        <tr><td style="padding:8px;color:#6f6256">反馈类型</td><td style="padding:8px;color:#2f2118;font-weight:bold">${data.type || '--'}</td></tr>
        <tr><td style="padding:8px;color:#6f6256">城市</td><td style="padding:8px;color:#2f2118">${data.city || '--'}</td></tr>
        <tr><td style="padding:8px;color:#6f6256">天气</td><td style="padding:8px;color:#2f2118">${data.weather || '--'}</td></tr>
        <tr><td style="padding:8px;color:#6f6256">温度</td><td style="padding:8px;color:#2f2118">${data.temp || '--'}</td></tr>
        <tr><td style="padding:8px;color:#6f6256">备注</td><td style="padding:8px;color:#2f2118">${data.note || '无'}</td></tr>
        <tr><td style="padding:8px;color:#6f6256">用户ID</td><td style="padding:8px;color:#2f2118">${data.userId || '--'}</td></tr>
      </table>
    </div>`
  );
}

module.exports = { sendEmailCode, sendWeatherFeedback };
