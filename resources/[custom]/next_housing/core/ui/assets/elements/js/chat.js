/*
  ------------------------------------------------------------------------------------------------
    Next Housing - Complete housing system
  ------------------------------------------------------------------------------------------------
  _   _ ________   _________ _____ ____  _____  ______ 
 | \ | |  ____\ \ / /__   __/ ____/ __ \|  __ \|  ____|
 |  \| | |__   \ V /   | | | |   | |  | | |__) | |__   
 | . ` |  __|   > <    | | | |   | |  | |  _  /|  __|  
 | |\  | |____ / . \   | | | |___| |__| | | \ \| |____ 
 |_| \_|______/_/ \_\  |_|  \_____\____/|_|  \_\______|                                                       
                                                       
  ------------------------------------------------------------------------------------------------
    Created for Nextcore Studio by Junnho
  ------------------------------------------------------------------------------------------------
    
    Author: Nextcore Studio
    Copyright © 2025 Junnho. All rights reserved.
    Copyright © 2025 Nextcore Studio. All rights reserved.
    License: EULA (see LICENSE file)
    
    Documentation: https://www.nextcorestudio.com/docs/next-housing/
    Website: https://www.nextcorestudio.com/
    Script Page: https://www.nextcorestudio.com/scripts/next-housing/
    Tebex: https://junnho.tebex.io/package/7057755

--------------------------------------------------------------------------------------------------
*/
let papCurrentChatOfferId = null;
let papChatMessages = [];
let papChatIsSeller = false;
let papChatBuyerName = '';
let papChatSellerName = '';
let papChatSending = false;

function papChatText(key, fallback) {
    const translated = papT(key);
    return (translated && translated !== key) ? translated : fallback;
}

function papOpenChat(offerId, isSeller, buyerName, sellerName) {
    papCurrentChatOfferId = offerId;
    papChatIsSeller = !!isSeller;
    papChatBuyerName = buyerName || papChatText('pap_contract_buyer');
    papChatSellerName = sellerName || papChatText('pap_contract_seller');

    const otherPartyName = papChatIsSeller ? papChatBuyerName : papChatSellerName;
    const sendLabel = papChatText('pap_chat_send');

    window.ModalManager.open({
        title: papChatText('pap_chat_title'),
        hint: otherPartyName,
        containerClass: 'pap-chat-modal',
        bodyHTML: `
            <div class="pap-chat-layout">
                <div id="pap-chat-messages" class="pap-chat-messages">
                    ${papBuildChatEmptyState('loading')}
                </div>

                <div id="pap-chat-footer" class="pap-chat-footer">
                    <div class="pap-chat-input-shell">
                        <input type="text" id="pap-chat-input" class="pap-chat-input" maxlength="500"
                            placeholder="${papEscapeHtml(papChatText('pap_chat_input_placeholder'))}"
                            onkeydown="papChatInputKeypress(event)">
                        <button class="pap-chat-send" onclick="papSendMessage()" type="button" aria-label="${papEscapeHtml(sendLabel)}" title="${papEscapeHtml(sendLabel)}">
                            <i class="ph ph-paper-plane-tilt"></i>
                        </button>
                    </div>
                </div>
            </div>
        `,
        onOpen: function () {
            papModalOpen = true;
            papLoadMessages(offerId);
            setTimeout(function () {
                const input = document.getElementById('pap-chat-input');
                if (input) {
                    input.focus();
                }
            }, 60);
        },
        onClose: function () {
            papCurrentChatOfferId = null;
            papChatMessages = [];
            papChatSending = false;
            papModalOpen = false;
        }
    });
}

function papCloseChatModal() {
    if (window.ModalManager) {
        window.ModalManager.close();
    }
}

function papBuildChatEmptyState(type, errorMessage) {
    if (type === 'error') {
        return `
            <div class="pap-chat-empty">
                <span class="pap-chat-empty-icon"><i class="ph ph-warning-circle"></i></span>
                <span class="pap-chat-empty-text">${papEscapeHtml(errorMessage || papChatText('pap_chat_load_error'))}</span>
            </div>
        `;
    }

    if (type === 'loading') {
        return `
            <div class="pap-chat-empty">
                <span class="pap-chat-empty-icon"><i class="ph ph-chats"></i></span>
                <span class="pap-chat-empty-text">${papEscapeHtml(papChatText('pap_chat_loading'))}</span>
            </div>
        `;
    }

    const emptyHint = papChatText('pap_chat_empty_hint');

    return `
        <div class="pap-chat-empty">
            <span class="pap-chat-empty-icon"><i class="ph ph-chats"></i></span>
            <span class="pap-chat-empty-text">${papEscapeHtml(papChatText('pap_chat_empty'))}${emptyHint ? `<br>${papEscapeHtml(emptyHint)}` : ''}</span>
        </div>
    `;
}

function papLoadMessages(offerId) {
    $.post('https://next_housing/papGetMessages', JSON.stringify({
        offerId: offerId
    }), function (response) {
        if (response && response.success) {
            papChatMessages = response.messages || [];
            papChatIsSeller = !!response.isSeller;
            papChatBuyerName = response.buyerName || papChatText('pap_contract_buyer');
            papChatSellerName = response.sellerName || papChatText('pap_contract_seller');

            const canChat = !response.offerStatus ||
                response.offerStatus === 'pending' ||
                response.offerStatus === 'offer_pending' ||
                response.offerStatus === 'accepted';

            papSetChatAvailability(canChat);
            papRenderChatMessages();
            return;
        }

        papRenderChatError((response && response.error) || papChatText('pap_chat_load_error'));
    }).fail(function () {
        papRenderChatError(papChatText('pap_chat_load_error'));
    });
}

function papSetChatAvailability(canChat) {
    const footer = document.getElementById('pap-chat-footer');
    const input = document.getElementById('pap-chat-input');
    const sendBtn = document.querySelector('.pap-chat-send');

    if (!footer || !input || !sendBtn) {
        return;
    }

    footer.classList.toggle('pap-chat-disabled', !canChat);
    input.disabled = !canChat;
    sendBtn.disabled = !canChat;
}

function papRenderChatMessages() {
    const container = document.getElementById('pap-chat-messages');
    if (!container) {
        return;
    }

    if (!papChatMessages.length) {
        container.innerHTML = papBuildChatEmptyState('empty');
        return;
    }

    const htmlParts = [];
    let previousDayKey = '';

    papChatMessages.forEach(function (msg) {
        const dateObj = papParseChatTimestamp(msg.timestamp);
        const dayKey = dateObj ? `${dateObj.getFullYear()}-${dateObj.getMonth()}-${dateObj.getDate()}` : '';

        if (dayKey && dayKey !== previousDayKey) {
            previousDayKey = dayKey;
            htmlParts.push(`<div class="pap-chat-separator">${papFormatChatDay(dateObj)}</div>`);
        }

        const isFromMe = papIsChatMessageFromMe(msg);
        const senderName = papEscapeHtml(msg.senderName || (isFromMe ? papChatText('common_me') : papChatText('pap_contract_seller')));
        const safeContent = papEscapeHtml(msg.content || '').replace(/\n/g, '<br>');

        htmlParts.push(`
            <div class="pap-chat-bubble-wrap ${isFromMe ? 'me' : 'them'}">
                <div class="pap-chat-bubble ${isFromMe ? 'me' : 'them'}">
                    <div class="pap-chat-meta">
                        <span class="pap-chat-sender">${senderName}</span>
                        <span class="pap-chat-time">${papEscapeHtml(papFormatChatTime(msg.timestamp))}</span>
                    </div>
                    <div class="pap-chat-content">${safeContent}</div>
                </div>
            </div>
        `);
    });

    container.innerHTML = htmlParts.join('');
    container.scrollTop = container.scrollHeight;
}

function papIsChatMessageFromMe(msg) {
    if (papChatIsSeller) {
        return msg.senderName === papChatSellerName;
    }

    return msg.senderName === papChatBuyerName || !!msg.isInitial;
}

function papRenderChatError(error) {
    const container = document.getElementById('pap-chat-messages');
    if (container) {
        container.innerHTML = papBuildChatEmptyState('error', error);
    }
}

function papParseChatTimestamp(timestamp) {
    if (!timestamp && timestamp !== 0) {
        return null;
    }

    let parsedDate = null;

    if (typeof timestamp === 'number') {
        const normalized = timestamp < 1e12 ? timestamp * 1000 : timestamp;
        parsedDate = new Date(normalized);
    } else if (typeof timestamp === 'string') {
        const trimmed = timestamp.trim();
        const numeric = Number(trimmed);

        if (trimmed !== '' && Number.isFinite(numeric)) {
            const normalized = numeric < 1e12 ? numeric * 1000 : numeric;
            parsedDate = new Date(normalized);
        } else {
            parsedDate = new Date(trimmed);
        }
    } else {
        parsedDate = new Date(timestamp);
    }

    if (!parsedDate || Number.isNaN(parsedDate.getTime())) {
        return null;
    }

    return parsedDate;
}

function papFormatChatDay(dateObj) {
    if (!dateObj) {
        return '';
    }

    return dateObj.toLocaleDateString(undefined, {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    });
}

function papFormatChatTime(timestamp) {
    const date = papParseChatTimestamp(timestamp);
    if (!date) {
        return '';
    }

    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const dateStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const diffDays = Math.round((todayStart - dateStart) / (1000 * 60 * 60 * 24));

    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const time = `${hours}:${minutes}`;

    if (diffDays === 0) {
        return papChatText('pap_chat_today').replace(/%[sd]/, time);
    }

    if (diffDays === 1) {
        return papChatText('pap_chat_yesterday').replace(/%[sd]/, time);
    }

    const day = date.getDate().toString().padStart(2, '0');
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    return `${day}/${month} ${time}`;
}

function papSendMessage() {
    if (papChatSending || !papCurrentChatOfferId) {
        return;
    }

    const input = document.getElementById('pap-chat-input');
    const sendBtn = document.querySelector('.pap-chat-send');

    if (!input || !sendBtn || input.disabled || sendBtn.disabled) {
        return;
    }

    const content = input.value.trim();
    if (!content) {
        return;
    }

    papChatSending = true;
    input.value = '';
    sendBtn.disabled = true;

    $.post('https://next_housing/papSendMessage', JSON.stringify({
        offerId: papCurrentChatOfferId,
        content: content
    }), function (response) {
        if (response && response.success === false) {
            papRenderChatError(response.error || papChatText('pap_chat_send_error'));
        }
    }).fail(function () {
        papRenderChatError(papChatText('pap_chat_send_error'));
    }).always(function () {
        papChatSending = false;
        if (!input.disabled) {
            sendBtn.disabled = false;
        }
    });
}

function papChatInputKeypress(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        papSendMessage();
    }
}

function papHandleNewMessage(data) {
    if (!data || data.offerId !== papCurrentChatOfferId || !data.message) {
        return;
    }

    papChatMessages.push(data.message);
    papRenderChatMessages();
}

window.papChatOpenChatImpl = papOpenChat;
window.papChatCloseChatModalImpl = papCloseChatModal;
window.papChatLoadMessagesImpl = papLoadMessages;
window.papChatSendMessageImpl = papSendMessage;
window.papChatInputKeypressImpl = papChatInputKeypress;
window.papChatHandleNewMessageImpl = papHandleNewMessage;

window.papOpenChat = papOpenChat;
window.papCloseChatModal = papCloseChatModal;
window.papLoadMessages = papLoadMessages;
window.papSendMessage = papSendMessage;
window.papChatInputKeypress = papChatInputKeypress;
window.papHandleNewMessage = papHandleNewMessage;
