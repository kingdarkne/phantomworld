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
var ModalManager = window.ModalManager = {
    isOpen: false,
    currentConfig: null,
    modalStack: [],

    
    init: function () {
        this.$modal = $('#dynamic-global-modal');
        if (this.$modal.length === 0) {
            console.error('[ModalManager] #dynamic-global-modal not found in DOM.');
            return;
        }

        this.$overlay = this.$modal.find('.pap-modal-overlay');
        this.$content = this.$modal.find('.pap-modal-content');
        this.$header = this.$modal.find('.pap-modal-header');
        this.$subtitle = this.$modal.find('#dynamic-modal-subtitle');
        this.$hint = this.$modal.find('#dynamic-modal-hint');
        this.$body = this.$modal.find('.pap-modal-body');
        this.$footer = this.$modal.find('.pap-modal-footer');
        this.$closeBtn = this.$modal.find('#dynamic-modal-close');

        const consumeInteractionEvent = (e) => {
            if (!e) return;
            e.preventDefault();
            e.stopPropagation();
            if (typeof e.stopImmediatePropagation === 'function') {
                e.stopImmediatePropagation();
            }
        };

        this.$closeBtn
            .off('.dynamicModalClose')
            .on('mousedown.dynamicModalClose mouseup.dynamicModalClose click.dynamicModalClose', (e) => {
                consumeInteractionEvent(e);
                if (e.type === 'click') {
                    this.close();
                }
            });

        $(document).off('keydown.dynamicModal').on('keydown.dynamicModal', (e) => {
            if (e.key === 'Escape' && this.isOpen) {
                if ($('#image-lightbox').length && !$('#image-lightbox').hasClass('hidden')) {
                    e.preventDefault();
                    e.stopPropagation();
                    if (typeof e.stopImmediatePropagation === 'function') {
                        e.stopImmediatePropagation();
                    }
                    return;
                }
                e.preventDefault();
                e.stopPropagation();
                if (typeof e.stopImmediatePropagation === 'function') {
                    e.stopImmediatePropagation();
                }
                this.close();
            }
        });
    },

    render: function (config, invokeOnOpen) {
        this.currentConfig = config || {};
        if (this.$footer && this.$footer.length) {
            
            this.$body.after(this.$footer);
            this.$footer.removeClass('pap-modal-footer-integrated');
        }

        
        this.$content
            .attr('class', 'pap-modal-content')
            .css({
                width: '',
                maxWidth: '',
                height: '',
                maxHeight: ''
            });
        if (this.currentConfig.containerClass) {
            this.$content.addClass(this.currentConfig.containerClass);
        }

        const normalizeSizeValue = (value) => {
            if (value === null || value === undefined) return '';
            if (typeof value === 'number' && Number.isFinite(value)) {
                return `${value}px`;
            }
            return String(value).trim();
        };

        const shouldUseCustomSize = this.currentConfig.useCustomSize === true;
        if (shouldUseCustomSize) {
            const widthValue = normalizeSizeValue(this.currentConfig.width);
            if (widthValue) {
                this.$content.css('width', widthValue);
                if (!this.currentConfig.maxWidth) {
                    this.$content.css('maxWidth', '92vw');
                }
            }

            const maxWidthValue = normalizeSizeValue(this.currentConfig.maxWidth);
            if (maxWidthValue) {
                this.$content.css('maxWidth', maxWidthValue);
            }

            const heightValue = normalizeSizeValue(this.currentConfig.height);
            if (heightValue) {
                this.$content.css('height', heightValue);
            }

            const maxHeightValue = normalizeSizeValue(this.currentConfig.maxHeight);
            if (maxHeightValue) {
                this.$content.css('maxHeight', maxHeightValue);
            }
        }

        this.$subtitle.text(this.currentConfig.title || '');
        this.$hint.text(this.currentConfig.hint || '');
        this.syncPrimaryNavbar();

        this.$body.html(this.currentConfig.bodyHTML || '');
        this.applyMainBlockHeader();
        this.$footer.attr('class', 'pap-modal-footer');
        if (this.currentConfig.footerClass) {
            this.$footer.addClass(this.currentConfig.footerClass);
        }

        this.$footer.empty();
        if (this.currentConfig.buttons && this.currentConfig.buttons.length > 0) {
            this.$footer.show();
            this.currentConfig.buttons.forEach((btnConfig, index) => {
                const btnId = btnConfig.id || `dynamic-modal-btn-${index}`;
                const btnClass = btnConfig.class || 'pap-btn secondary';
                const $btn = $(`<button id="${btnId}" class="${btnClass}">${btnConfig.text}</button>`);

                if (typeof btnConfig.onClick === 'function') {
                    $btn.on('click', (e) => {
                        btnConfig.onClick(e, this);
                    });
                }

                this.$footer.append($btn);
            });

            if (this.shouldAutoAddMessageCancelButton()) {
                const cancelText = (window.translations && (
                    window.translations.job_modal_cancel_btn ||
                    window.translations.cancel ||
                    window.translations.close
                )) || 'Annuler';
                const $cancelBtn = $(`<button class="pap-btn secondary multimodal-action-btn multimodal-cancel-btn">${cancelText}</button>`);
                $cancelBtn.on('click', () => this.close());
                this.$footer.append($cancelBtn);
            }

            this.integrateFooterInMainBlock();
        } else {
            this.$footer.hide();
        }

        if (!this.isOpen) {
            this.$modal.removeClass('hidden');
            this.isOpen = true;
        }

        if (invokeOnOpen && typeof this.currentConfig.onOpen === 'function') {
            this.currentConfig.onOpen(this.$body, this);
        }
    },

    applyMainBlockHeader: function () {
        const headerConfig = this.currentConfig && this.currentConfig.mainBlockHeader;
        if (!headerConfig) return;

        const resolved = (typeof headerConfig === 'string')
            ? { title: headerConfig }
            : headerConfig;

        const title = (resolved && resolved.title) ? String(resolved.title).trim() : '';
        if (!title) return;

        const targetSelector = (resolved && resolved.target)
            ? String(resolved.target)
            : '.pap-main-block-target';

        const $target = this.$body.find(targetSelector).first();
        if (!$target.length) return;

        $target.children('.section-header.pap-main-block-header').remove();

        const $header = $('<div class="section-header pap-main-block-header"></div>');
        $header.append($('<h3></h3>').text(title));
        $target.prepend($header);
    },

    shouldRenderPrimaryNavbar: function () {
        if (this.currentConfig && this.currentConfig.showPrimaryNav === false) {
            return false;
        }

        const containerClass = (this.currentConfig && this.currentConfig.containerClass)
            ? String(this.currentConfig.containerClass)
            : '';
        const classList = containerClass.split(/\s+/).filter(Boolean);

        
        if (classList.includes('multimodal-message-modal')) {
            return false;
        }

        return true;
    },

    shouldAutoAddMessageCancelButton: function () {
        const containerClass = (this.currentConfig && this.currentConfig.containerClass)
            ? String(this.currentConfig.containerClass)
            : '';
        const classList = containerClass.split(/\s+/).filter(Boolean);

        if (!classList.includes('multimodal-message-modal')) {
            return false;
        }

        if (!this.currentConfig || this.currentConfig.autoCancelButton !== true) {
            return false;
        }

        const buttons = (this.currentConfig && Array.isArray(this.currentConfig.buttons))
            ? this.currentConfig.buttons
            : [];

        const hasCancelButton = buttons.some((btn) => {
            const idText = String((btn && btn.id) || '');
            const labelText = String((btn && btn.text) || '');
            return /cancel|annul/i.test(idText) || /cancel|annul/i.test(labelText);
        });

        return !hasCancelButton;
    },

    shouldIntegrateFooterInMainBlock: function () {
        if (this.currentConfig && this.currentConfig.integrateFooterInMainBlock === false) {
            return false;
        }

        if (!this.shouldRenderPrimaryNavbar()) {
            return false;
        }

        const containerClass = (this.currentConfig && this.currentConfig.containerClass)
            ? String(this.currentConfig.containerClass)
            : '';
        const classList = containerClass.split(/\s+/).filter(Boolean);

        if (classList.includes('pap-chat-modal')) {
            return false;
        }

        return true;
    },

    integrateFooterInMainBlock: function () {
        this.$footer.removeClass('pap-modal-footer-integrated');
        this.$body.find('.multimodal-footer-host').removeClass('multimodal-footer-host');

        if (!this.shouldIntegrateFooterInMainBlock()) {
            return;
        }

        if (!this.$footer.length || this.$footer.children().length === 0) {
            return;
        }

        const selectors = [
            '.agency-modal-main-block',
            '.pap-form-main-block',
            '.pap-main-block-target',
            '.agency-contract-create-modal',
            '.agency-house-details-main-block'
        ];

        let $target = $();
        for (let i = 0; i < selectors.length; i += 1) {
            $target = this.$body.find(selectors[i]).first();
            if ($target.length) {
                break;
            }
        }

        if (!$target.length) {
            
            const $wrapper = $('<div class="agency-modal-main-block"></div>');
            const $children = this.$body.children().not(this.$footer);
            if ($children.length) {
                $wrapper.append($children);
            }
            this.$body.append($wrapper);
            $target = $wrapper;
        }

        $target.addClass('multimodal-footer-host');
        $target.append(this.$footer);
        this.$footer.addClass('pap-modal-footer-integrated');
    },

    syncPrimaryNavbar: function () {
        this.$content.children('.multimodal-context-nav-real').remove();
        this.$content.removeClass('has-context-nav');

        if (!this.shouldRenderPrimaryNavbar()) {
            return;
        }

        const source = this.getPrimaryNavbarSource();
        if (!source || !source.$nav || !source.$nav.length || !source.tabSelector) {
            return;
        }

        const $sourceNav = source.$nav.first();
        const navClass = ($sourceNav.attr('class') || '').trim();
        const $tabs = $sourceNav.find(source.tabSelector).filter(':visible');
        if (!$tabs.length) {
            return;
        }

        
        const $clone = $('<div></div>');
        if (navClass) {
            $clone.attr('class', navClass);
        }

        const self = this;
        $tabs.each(function () {
            const $originalTab = $(this);
            const targetValue = String($originalTab.attr(source.keyAttr) || '').trim();
            if (!targetValue) {
                return;
            }

            const $tab = $originalTab.clone(false, false);
            $tab.removeAttr('id');
            $tab.find('[id]').removeAttr('id');
            $tab.find('[onclick]').removeAttr('onclick');
            $tab.on('click', function (e) {
                e.preventDefault();
                e.stopPropagation();
                self.handlePrimaryNavbarTabClick(source, targetValue);
            });
            $clone.append($tab);
        });

        const containerClass = (this.currentConfig && this.currentConfig.containerClass)
            ? String(this.currentConfig.containerClass)
            : '';
        const classList = containerClass.split(/\s+/).filter(Boolean);
        const shouldRenderBackButton = !classList.includes('agency-house-buy-modal');

        if (shouldRenderBackButton) {
            const backLabel = (window.translations && (
                window.translations.job_modal_back ||
                window.translations.back
            )) || 'Retour';
            const $backBtn = $('<button type="button" class="multimodal-nav-back-btn"></button>');
            $backBtn.append('<i class="ph ph-arrow-left"></i>');
            $backBtn.append($('<span></span>').text(backLabel));
            $backBtn.on('click', function (e) {
                e.preventDefault();
                e.stopPropagation();
                self.close();
            });
            $clone.append($backBtn);
        }

        const $wrapper = $('<div class="multimodal-context-nav-real"></div>');
        $wrapper.append($clone);

        this.$header.after($wrapper);
        this.$content.addClass('has-context-nav');
    },

    handlePrimaryNavbarTabClick: function (source, targetValue) {
        const tabValue = String(targetValue || '').trim();
        if (!tabValue) {
            return;
        }

        if (this.isOpen) {
            
            this.modalStack = [];
            this.close();
        }

        this.switchPrimaryInterfaceTab(source, tabValue);
    },

    switchPrimaryInterfaceTab: function (source, tabValue) {
        if (!source || !source.context) {
            return;
        }

        if (source.context === 'admin') {
            if (typeof window.activateTab === 'function') {
                window.activateTab(tabValue);
                return;
            }
            $(`#container .tab-bar .tab-btn[data-tab="${tabValue}"]`).first().trigger('click');
            return;
        }

        if (source.context === 'job') {
            if (typeof window.switchTab === 'function') {
                window.switchTab(tabValue);
                return;
            }
            $(`#job-interface .job-tabs .job-tab-btn[data-tab="${tabValue}"]`).first().trigger('click');
            return;
        }

        if (source.context === 'pap') {
            if (typeof window.papSwitchTab === 'function') {
                window.papSwitchTab(tabValue);
                return;
            }
            $(`#pap-interface .pap-tabs .pap-tab-btn[data-tab="${tabValue}"]`).first().trigger('click');
            return;
        }

        if (source.context === 'wardrobe') {
            if (typeof window.switchWardrobeTab === 'function') {
                window.switchWardrobeTab(tabValue);
                return;
            }
            $(`#wardrobe-container .wardrobe-navigation .wardrobe-nav-item[data-wardrobe-tab="${tabValue}"]`).first().trigger('click');
        }
    },

    getPrimaryNavbarSource: function () {
        const sources = [
            {
                context: 'job',
                isActive: function () {
                    return $('#job-interface').is(':visible') && !$('#job-interface').hasClass('hidden');
                },
                navSelector: '#job-interface .job-tabs',
                tabSelector: '.job-tab-btn[data-tab]',
                keyAttr: 'data-tab'
            },
            {
                context: 'pap',
                isActive: function () {
                    return $('#pap-interface').is(':visible') && !$('#pap-interface').hasClass('hidden');
                },
                navSelector: '#pap-interface .pap-tabs',
                tabSelector: '.pap-tab-btn[data-tab]',
                keyAttr: 'data-tab'
            },
            {
                context: 'wardrobe',
                isActive: function () {
                    return $('#wardrobe-container').is(':visible') && $('#wardrobe-container').hasClass('show');
                },
                navSelector: '#wardrobe-container .wardrobe-navigation',
                tabSelector: '.wardrobe-nav-item[data-wardrobe-tab]',
                keyAttr: 'data-wardrobe-tab'
            },
            {
                context: 'admin',
                isActive: function () {
                    return $('#container').is(':visible') && $('#container').hasClass('show');
                },
                navSelector: '#container .tab-bar',
                tabSelector: '.tab-btn[data-tab]',
                keyAttr: 'data-tab'
            }
        ];

        for (let i = 0; i < sources.length; i += 1) {
            const source = sources[i];
            if (!source.isActive()) {
                continue;
            }

            const $nav = $(source.navSelector).filter(':visible').first();
            if ($nav.length) {
                return {
                    context: source.context,
                    $nav: $nav,
                    tabSelector: source.tabSelector,
                    keyAttr: source.keyAttr
                };
            }
        }

        return null;
    },

    
    open: function (config) {
        if (!this.$modal) this.init();
        if (!this.$modal || this.$modal.length === 0) return;

        const nextConfig = config || {};
        if (nextConfig.stack === true && this.isOpen && this.currentConfig) {
            this.modalStack.push(this.currentConfig);
        }

        this.render(nextConfig, true);
    },

    
    close: function () {
        if (!this.isOpen) return;

        if (this.currentConfig && typeof this.currentConfig.onClose === 'function') {
            this.currentConfig.onClose(this);
        }

        if (this.modalStack.length > 0) {
            const previousConfig = this.modalStack.pop();
            this.render(previousConfig, true);
            return;
        }

        this.$modal.addClass('hidden');
        this.isOpen = false;

        setTimeout(() => {
            if (!this.isOpen) {
                this.$body.empty();
                this.$footer.empty();
                this.$subtitle.text('');
                this.$hint.text('');
                this.$content.children('.multimodal-context-nav-real').remove();
                this.$content.removeClass('has-context-nav');
                this.currentConfig = null;
                this.modalStack = [];
            }
        }, 300);
    }
};


$(function () {
    ModalManager.init();
});
