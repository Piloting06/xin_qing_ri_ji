const https = require('https');

const RESEND_API_KEY = process.env.RESEND_API_KEY || '';
const FROM_EMAIL = '拾晴日记 <noreply@sqrj.glxgo.xin>';

async function sendViaResend(to, subject, html) {
  const body = JSON.stringify({
    from: FROM_EMAIL,
    to: [to],
    subject,
    html,
  });

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.resend.com',
      path: '/emails',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`Resend API error ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

/** 发邮箱验证码 */
async function sendEmailCode(email, code) {
  await sendViaResend(email, '拾晴日记 - 邮箱验证码',
    `<div style="margin:0;padding:0;background:#fdfaf5">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#fdfaf5;padding:32px 0">
    <tr><td align="center">
      <table width="440" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.06)">
        <tr><td style="padding:40px 36px 32px;text-align:center">
          <p style="font-size:22px;color:#b8782c;font-weight:600;margin:0 0 6px;letter-spacing:1px">拾晴日记</p>
          <p style="font-size:12px;color:#b5a99a;margin:0 0 28px;letter-spacing:0.5px">记录天气，也记录你</p>
          <p style="font-size:15px;color:#4a3f35;margin:0 0 16px;line-height:1.7">你好，你的验证码是：</p>
          <div style="background:#fdfaf5;border-radius:14px;padding:22px 0;margin:0 0 20px">
            <span style="font-size:38px;font-weight:700;color:#b8782c;letter-spacing:10px;font-family:'Courier New',monospace">${code}</span>
          </div>
          <p style="font-size:13px;color:#9a8a7d;margin:0 0 0;line-height:1.6">验证码 5 分钟内有效，请勿泄露给他人</p>
        </td></tr>
        <tr><td style="padding:0 36px 28px">
          <div style="border-top:1px solid #f0e8dc"></div>
        </td></tr>
        <tr><td style="padding:0 36px 32px">
          <p style="font-size:11px;color:#c4b9ab;margin:0;text-align:center;line-height:1.5">如非本人操作，请忽略此邮件<br/>拾晴日记 · sqrj.hyfnoir.click</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</div>`
  );
}

/** 天气反馈邮件 */
async function sendWeatherFeedback(data) {
  await sendViaResend('3281607568@qq.com', `天气反馈 - ${data.type}`,
    `<div style="margin:0;padding:0;background:#fdfaf5">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#fdfaf5;padding:32px 0">
    <tr><td align="center">
      <table width="440" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.06)">
        <tr><td style="padding:36px 36px 28px;text-align:center">
          <p style="font-size:20px;color:#b8782c;font-weight:600;margin:0 0 4px;letter-spacing:1px">天气反馈</p>
          <p style="font-size:12px;color:#b5a99a;margin:0 0 24px">${data.type || ''}</p>
        </td></tr>
        <tr><td style="padding:0 36px 28px">
          <table width="100%" cellpadding="0" cellspacing="0" style="font-size:14px;line-height:1.8;color:#4a3f35">
            <tr><td style="padding:10px 0;border-bottom:1px solid #f5efe8;color:#9a8a7d;width:90px">城市</td><td style="padding:10px 0;border-bottom:1px solid #f5efe8">${data.city || '--'}</td></tr>
            <tr><td style="padding:10px 0;border-bottom:1px solid #f5efe8;color:#9a8a7d">天气</td><td style="padding:10px 0;border-bottom:1px solid #f5efe8">${data.weather || '--'}</td></tr>
            <tr><td style="padding:10px 0;border-bottom:1px solid #f5efe8;color:#9a8a7d">温度</td><td style="padding:10px 0;border-bottom:1px solid #f5efe8">${data.temp || '--'}</td></tr>
            <tr><td style="padding:10px 0;border-bottom:1px solid #f5efe8;color:#9a8a7d">备注</td><td style="padding:10px 0;border-bottom:1px solid #f5efe8">${data.note || '无'}</td></tr>
            <tr><td style="padding:10px 0;color:#9a8a7d">用户ID</td><td style="padding:10px 0">${data.userId || '--'}</td></tr>
          </table>
        </td></tr>
        <tr><td style="padding:0 36px 32px">
          <p style="font-size:11px;color:#c4b9ab;margin:0;text-align:center">拾晴日记 · 天气反馈系统</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</div>`
  );
}

module.exports = { sendEmailCode, sendWeatherFeedback };
