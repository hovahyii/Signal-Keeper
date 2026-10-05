// Signal Keeper Mobile Game Website & Compliance Scripts

const i18nData = {
  zh: {
    legal_portal: "合规与隐私服务门户",
    nav_about: "游戏介绍",
    nav_features: "核心特色",
    nav_how_to_play: "玩法指引",
    nav_simulator: "在线体验",
    nav_release: "版本说明",
    nav_compliance: "审核与合规",
    nav_home: "首页概览",
    nav_privacy: "隐私政策",
    nav_rights: "主体权利",
    hero_h1: "每一个连接 <span>都至关重要。</span>",
    hero_pitch: "《Signal Keeper》是一款每个连接都至关重要的紧凑型逻辑解谜游戏。",
    hero_story: "您将负责修复受损的中继基站，引导信号从发射源准确传输至接收终端。在应对干扰和有限的维修资源的同时，旋转中继节点，建立有效连接，保持传输信号的持续稳定。",
    hero_core_idea: "<strong>核心理念：</strong> 每个谜题都围绕一个简单的想法构建：理解网络、找到正确路径、恢复信号传输。",
    btn_dl_apk: "下载游戏安装包 (APK)",
    btn_how_play: "游戏玩法规则",
    btn_appgallery_review: "华为审核网址指引",
    feat_tag: "战术中继网络系统",
    feat_head: "核心特色",
    feat_sub: "探索呈现于细腻像素艺术下的黑暗中继站，伴随青色信号通路、琥珀色警告与红色干扰状态。",
    feat_1_title: "旋转并连接 (ROTATE AND CONNECT)",
    feat_1_desc: "旋转工业级中继节点，在信号源与接收器之间搭建一条连续无间断的通路。",
    feat_2_title: "保持信号稳定 (KEEP THE SIGNAL STABLE)",
    feat_2_desc: "构建完整通路仅是挑战的一部分。密切观察信号状态，在电磁干扰威胁连接时迅速做出反应。",
    feat_3_title: "合理调配维修资源 (MANAGE REPAIRS)",
    feat_3_desc: "当中继网络的部分组件变得不稳定或损坏时，谨慎利用有限的维修与步数资源。",
    feat_4_title: "洞悉网络状态 (READ THE NETWORK)",
    feat_4_desc: "清晰直观的视觉反馈助您迅速识别通路、不稳定中继、受损组件及有效交互点。",
    feat_5_title: "紧凑型关卡设计 (COMPACT PUZZLE LEVELS)",
    feat_5_desc: "专为短平快且深度的战术挑战打造，奖励观察力、前瞻规划与逻辑尝试。",
    feat_6_title: "工业复古像素风 (INDUSTRIAL PIXEL-ART STYLE)",
    feat_6_desc: "探索精雕细琢的暗黑科技中继站，感受青色高能脉冲、琥珀色告警与红色干扰流的视觉冲击。",
    htp_tag: "操作协议",
    htp_title: "游戏玩法指引 (HOW TO PLAY)",
    htp_desc: "掌握以下六大关键步骤，恢复中继传输并维持网络在线。",
    htp_1_title: "确认端点位置",
    htp_1_desc: "1. 确定信号源 (Source) 与接收终端 (Receiver) 的位置。",
    htp_2_title: "选择并旋转中继",
    htp_2_desc: "2. 选择并顺时针旋转中继管道节点。",
    htp_3_title: "搭建有效回路",
    htp_3_desc: "3. 在复杂的网络中构建出一条合法的闭环传输路线。",
    htp_4_title: "监测稳定性与资源",
    htp_4_desc: "4. 密切观察信号稳定性指标及当前剩余的维修步数。",
    htp_5_title: "应对干扰与受损点",
    htp_5_desc: "5. 妥善响应突发的信号干扰与损坏断路。",
    htp_6_title: "完成中继测试",
    htp_6_desc: "6. 成功输送稳定信号，顺利完成本轮中继阵列测试。",
    htp_challenge_q: "您能否在全网崩溃前彻底恢复连接？",
    htp_challenge_call: "进入中继站，解读信号，维系它的生命。",
    sim_tag: "网页模拟器",
    sim_title: "在浏览器中试玩管道中继交互",
    sim_desc: "点击下方的电路方块即可顺时针旋转90度。尝试让信号从左侧贯通至右侧，点亮脉冲！",
    rn_tag: "首发版本规范",
    rn_title: "Signal Keeper 初始发布版特性",
    rn_desc: "首发版本包含的核心机制与游戏系统：",
    comp_tag: "合规与审核公示",
    comp_title: "华为 AppGallery 审核网址及法律声明",
    comp_desc: "请向应用或元服务审核及客户端展示提供隐私政策 URL 及数据主体权利 URL（严格遵循《华为应用市场审核指南》及个人信息保护 FAQ）：",
    card_pp_title: "1. 隐私政策网址 (Privacy policy URL)",
    card_pp_badge: "对应 AGC 后台「隐私声明网址」字段",
    card_pp_body: "详尽公开单机离线存档存储机制、极简设备权限（仅联网用于广告）、华为 Petal Ads SDK 目录（OAID标识符与非个性化广告）、未成年人保护及数据安全保障措施。",
    card_dsr_title: "2. 个人信息主体权利网址 (Data subject right URL)",
    card_dsr_badge: "对应 AGC 后台「个人信息主体权利URL」字段",
    card_dsr_body: "为用户提供查阅、清除本地数据、HarmonyOS/Android系统OAID重置教程及免账号注销声明，严格遵循不超过15个工作日答复处理承诺。",
    btn_view_pp: "查看完整隐私政策 &rarr;",
    btn_view_dsr: "查看主体权利平台 &rarr;",
    btn_copy_url: "📋 复制链接"
  }
};

// State
let currentLang = localStorage.getItem('sk_lang') || 'en';
let currentTheme = localStorage.getItem('sk_theme') || 'dark';

// Init Theme
function initTheme() {
  if (currentTheme === 'light') {
    document.documentElement.setAttribute('data-theme', 'light');
    const icon = document.getElementById('themeIcon');
    if (icon) icon.textContent = '🌙';
  } else {
    document.documentElement.removeAttribute('data-theme');
    const icon = document.getElementById('themeIcon');
    if (icon) icon.textContent = '☀️';
  }
}

function toggleTheme() {
  currentTheme = currentTheme === 'dark' ? 'light' : 'dark';
  localStorage.setItem('sk_theme', currentTheme);
  initTheme();
}

// Language Switcher
function applyLanguage(lang) {
  currentLang = lang;
  localStorage.setItem('sk_lang', lang);
  const langLabel = document.getElementById('langLabel');

  if (lang === 'zh') {
    if (langLabel) langLabel.textContent = 'English';
    const dict = i18nData.zh;
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (dict[key]) {
        el.innerHTML = dict[key];
      }
    });
    document.documentElement.lang = 'zh-CN';
  } else {
    if (langLabel) langLabel.textContent = '中文';
    location.reload();
  }
}

function toggleLanguage() {
  if (currentLang === 'en') {
    applyLanguage('zh');
  } else {
    localStorage.setItem('sk_lang', 'en');
    currentLang = 'en';
    location.reload();
  }
}

// Toast helper
function showToast(message) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 2600);
}

// Copy Text Helper
function copyTextToClipboard(text, successMsg) {
  navigator.clipboard.writeText(text).then(() => {
    showToast(successMsg || (currentLang === 'zh' ? '已复制到剪贴板！' : 'Copied to clipboard!'));
  }).catch(() => {
    showToast(currentLang === 'zh' ? '复制失败，请手动选择复制' : 'Failed to copy, please copy manually');
  });
}

// Interactive Simulator Logic
function initSimulator() {
  const tiles = document.querySelectorAll('.sim-tile');
  const simMovesEl = document.getElementById('simMoves');
  const simStatusEl = document.getElementById('simStatus');
  const resetBtn = document.getElementById('resetSimBtn');
  if (!tiles.length) return;

  let moves = 0;

  function updateTileTransform(tile, rot) {
    tile.setAttribute('data-rot', rot);
    tile.style.transform = `rotate(${rot * 90}deg)`;
  }

  function checkSolution() {
    // Check if path connects from left to right (tiles 3, 4, 5)
    const t3 = parseInt(document.getElementById('tile-3')?.getAttribute('data-rot') || '0', 10) % 2;
    const t4 = parseInt(document.getElementById('tile-4')?.getAttribute('data-rot') || '0', 10);
    const t5 = parseInt(document.getElementById('tile-5')?.getAttribute('data-rot') || '0', 10) % 2;

    // Direct straight path check or connected circuit
    const connected = (t3 === 1 && t5 === 1);
    if (connected) {
      if (simStatusEl) {
        simStatusEl.textContent = currentLang === 'zh' ? '传输稳定 (SIGNAL STABLE)' : 'SIGNAL STABLE';
        simStatusEl.style.color = 'var(--accent-cyan)';
      }
      tiles.forEach(t => t.style.borderColor = 'var(--accent-cyan)');
    } else {
      if (simStatusEl) {
        simStatusEl.textContent = currentLang === 'zh' ? '未导通 (INCOMPLETE)' : 'INCOMPLETE';
        simStatusEl.style.color = 'var(--accent-amber)';
      }
      tiles.forEach(t => t.style.borderColor = '#36536e');
    }
  }

  tiles.forEach(tile => {
    let rot = parseInt(tile.getAttribute('data-rot') || '0', 10);
    updateTileTransform(tile, rot);

    tile.addEventListener('click', () => {
      rot = (rot + 1) % 4;
      updateTileTransform(tile, rot);
      moves++;
      if (simMovesEl) simMovesEl.textContent = moves;
      checkSolution();
    });
  });

  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      tiles.forEach(tile => {
        const randRot = Math.floor(Math.random() * 4);
        updateTileTransform(tile, randRot);
      });
      moves = 0;
      if (simMovesEl) simMovesEl.textContent = '0';
      checkSolution();
      showToast(currentLang === 'zh' ? '中继网络已打乱重置！' : 'Relay network shuffled!');
    });
  }

  checkSolution();
}

// Initialize on DOM load
document.addEventListener('DOMContentLoaded', () => {
  initTheme();

  if (currentLang === 'zh') {
    applyLanguage('zh');
  }

  const themeToggle = document.getElementById('themeToggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', toggleTheme);
  }

  const langToggle = document.getElementById('langToggle');
  if (langToggle) {
    langToggle.addEventListener('click', toggleLanguage);
  }

  // Copy buttons
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-target');
      const targetEl = document.getElementById(targetId);
      if (targetEl) {
        copyTextToClipboard(targetEl.textContent.trim(), currentLang === 'zh' ? '链接已成功复制！' : 'URL copied to clipboard!');
      }
    });
  });

  initSimulator();
});
