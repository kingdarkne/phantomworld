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
(function () {
    var activeDropdown = null;
    var dropdownCounter = 0;
    var dropdownObserver = null;
    var targetSelectClasses = [
        'custom-select-target',
        'filter-select',
        'pap-filter-select',
        'pap-form-select'
    ];

    function shouldEnhanceSelect(selectEl) {
        if (!selectEl || selectEl.tagName !== 'SELECT') return false;
        if (selectEl.dataset && selectEl.dataset.customDropdownDisabled === 'true') return false;

        for (var i = 0; i < targetSelectClasses.length; i++) {
            if (selectEl.classList.contains(targetSelectClasses[i])) {
                return true;
            }
        }

        return false;
    }

    function buildDropdownFromSelect(selectEl) {
        if (!shouldEnhanceSelect(selectEl)) return null;
        if (selectEl.dataset.customDropdownInit === 'true') return;
        selectEl.dataset.customDropdownInit = 'true';

        var wrapper = document.createElement('div');
        wrapper.className = 'custom-dropdown';
        var dropdownId = 'custom-dropdown-' + (++dropdownCounter);
        wrapper.dataset.dropdownId = dropdownId;

        if (selectEl.style.flex) {
            wrapper.style.flex = selectEl.style.flex;
        }
        if (selectEl.style.width) {
            wrapper.style.width = selectEl.style.width;
        }

        var trigger = document.createElement('div');
        trigger.className = 'custom-dropdown-trigger';
        trigger.setAttribute('tabindex', '0');

        var triggerText = document.createElement('span');
        triggerText.className = 'custom-dropdown-trigger-text';
        trigger.appendChild(triggerText);

        var triggerArrow = document.createElement('span');
        triggerArrow.className = 'custom-dropdown-arrow';
        trigger.appendChild(triggerArrow);

        var listContainer = document.createElement('div');
        listContainer.className = 'custom-dropdown-list';
        listContainer.dataset.dropdownId = dropdownId;
        document.body.appendChild(listContainer);

        function buildOptions() {
            listContainer.innerHTML = '';
            var children = selectEl.children;

            for (var i = 0; i < children.length; i++) {
                var child = children[i];

                if (child.tagName === 'OPTGROUP') {
                    var groupLabel = document.createElement('div');
                    groupLabel.className = 'custom-dropdown-group-label';
                    groupLabel.textContent = child.label;
                    listContainer.appendChild(groupLabel);

                    var groupOptions = child.children;
                    for (var j = 0; j < groupOptions.length; j++) {
                        listContainer.appendChild(createOptionEl(groupOptions[j]));
                    }
                } else if (child.tagName === 'OPTION') {
                    listContainer.appendChild(createOptionEl(child));
                }
            }
        }

        function createOptionEl(optionEl) {
            var optDiv = document.createElement('div');
            optDiv.className = 'custom-dropdown-option';
            optDiv.dataset.value = optionEl.value;
            optDiv.textContent = optionEl.textContent.trim();

            if (optionEl.selected) {
                optDiv.classList.add('selected');
            }

            optDiv.addEventListener('click', function (e) {
                e.stopPropagation();
                selectEl.value = optionEl.value;

                var changeEvent = new Event('change', { bubbles: true });
                selectEl.dispatchEvent(changeEvent);

                if (selectEl.hasAttribute('onchange')) {
                    var onchangeFn = selectEl.getAttribute('onchange');
                    try { new Function(onchangeFn)(); } catch (err) { }
                }

                updateSelection();
                closeDropdown();
            });

            return optDiv;
        }

        function updateSelection() {
            var selectedOption = selectEl.options[selectEl.selectedIndex];
            triggerText.textContent = selectedOption ? selectedOption.textContent.trim() : '';

            var allOpts = listContainer.querySelectorAll('.custom-dropdown-option');
            for (var k = 0; k < allOpts.length; k++) {
                allOpts[k].classList.remove('selected');
                if (allOpts[k].dataset.value === selectEl.value) {
                    allOpts[k].classList.add('selected');
                }
            }
        }

        function positionList() {
            var rect = trigger.getBoundingClientRect();
            listContainer.style.top = (rect.bottom + 4) + 'px';
            listContainer.style.left = rect.left + 'px';
            listContainer.style.width = rect.width + 'px';
        }

        function openDropdown() {
            closeAllDropdowns();
            activeDropdown = { wrapper: wrapper, listContainer: listContainer };
            wrapper.classList.add('open');
            listContainer.classList.add('open');
            positionList();

            var selectedItem = listContainer.querySelector('.custom-dropdown-option.selected');
            if (selectedItem) {
                setTimeout(function () {
                    selectedItem.scrollIntoView({ block: 'nearest' });
                }, 10);
            }
        }

        function closeDropdown() {
            wrapper.classList.remove('open');
            listContainer.classList.remove('open');
            if (activeDropdown && activeDropdown.wrapper === wrapper) {
                activeDropdown = null;
            }
        }

        trigger.addEventListener('click', function (e) {
            e.stopPropagation();
            if (wrapper.classList.contains('open')) {
                closeDropdown();
            } else {
                openDropdown();
            }
        });

        listContainer.addEventListener('click', function (e) {
            e.stopPropagation();
        });

        buildOptions();
        updateSelection();

        wrapper.appendChild(trigger);

        selectEl.style.display = 'none';
        selectEl.parentNode.insertBefore(wrapper, selectEl.nextSibling);

        wrapper._selectEl = selectEl;
        wrapper._buildOptions = buildOptions;
        wrapper._updateSelection = updateSelection;
        wrapper._closeDropdown = closeDropdown;
        wrapper._listContainer = listContainer;

        return wrapper;
    }

    function ensureDropdownBuilt(selectEl) {
        if (!shouldEnhanceSelect(selectEl)) return null;

        var wrapper = selectEl.nextElementSibling;
        if (wrapper && wrapper.classList.contains('custom-dropdown')) {
            return wrapper;
        }

        if (selectEl.dataset.customDropdownInit === 'true') {
            selectEl.dataset.customDropdownInit = 'false';
        }

        buildDropdownFromSelect(selectEl);

        wrapper = selectEl.nextElementSibling;
        if (wrapper && wrapper.classList.contains('custom-dropdown')) {
            return wrapper;
        }

        return null;
    }

    function closeAllDropdowns() {
        if (activeDropdown) {
            activeDropdown.wrapper.classList.remove('open');
            activeDropdown.listContainer.classList.remove('open');
            activeDropdown = null;
        }
    }

    function cleanupOrphanDropdownLists() {
        var lists = document.querySelectorAll('.custom-dropdown-list[data-dropdown-id]');
        for (var i = 0; i < lists.length; i++) {
            var list = lists[i];
            var listId = list.dataset.dropdownId;
            if (!listId) continue;
            var owner = document.querySelector('.custom-dropdown[data-dropdown-id="' + listId + '"]');
            if (!owner) {
                if (activeDropdown && activeDropdown.listContainer === list) {
                    activeDropdown = null;
                }
                list.remove();
            }
        }
    }

    document.addEventListener('click', function () {
        closeAllDropdowns();
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            closeAllDropdowns();
        }
    });

    window.initCustomDropdowns = function () {
        cleanupOrphanDropdownLists();
        var selects = document.querySelectorAll('select');
        selects.forEach(function (s) {
            ensureDropdownBuilt(s);
        });
    };

    window.refreshCustomDropdown = function (selectId) {
        var selectEl = document.getElementById(selectId);
        if (!selectEl) return;

        var wrapper = ensureDropdownBuilt(selectEl);
        if (wrapper && wrapper.classList.contains('custom-dropdown')) {
            wrapper._buildOptions();
            wrapper._updateSelection();
        }
    };

    window.syncCustomDropdown = function (selectId) {
        var selectEl = document.getElementById(selectId);
        if (!selectEl) return;

        var wrapper = ensureDropdownBuilt(selectEl);
        if (wrapper && wrapper.classList.contains('custom-dropdown')) {
            wrapper._updateSelection();
        }
    };

    function hookJQueryVal() {
        if (typeof $ === 'undefined' && typeof jQuery === 'undefined') return;

        var jq = $ || jQuery;
        var originalVal = jq.fn.val;

        jq.fn.val = function () {
            var result = originalVal.apply(this, arguments);

            if (arguments.length > 0) {
                this.each(function () {
                    if (shouldEnhanceSelect(this)) {
                        var w = ensureDropdownBuilt(this);
                        if (w && w.classList.contains('custom-dropdown') && w._updateSelection) {
                            w._updateSelection();
                        }
                    }
                });
            }

            return result;
        };
    }

    function observeDynamicSelects() {
        if (dropdownObserver || typeof MutationObserver === 'undefined') return;
        if (!document.body) return;

        dropdownObserver = new MutationObserver(function (mutations) {
            for (var i = 0; i < mutations.length; i++) {
                var addedNodes = mutations[i].addedNodes;
                if (!addedNodes || !addedNodes.length) continue;

                for (var j = 0; j < addedNodes.length; j++) {
                    var node = addedNodes[j];
                    if (!node || node.nodeType !== 1) continue;

                    if (node.tagName === 'SELECT') {
                        ensureDropdownBuilt(node);
                    }

                    if (node.querySelectorAll) {
                        var nestedSelects = node.querySelectorAll('select');
                        for (var k = 0; k < nestedSelects.length; k++) {
                            ensureDropdownBuilt(nestedSelects[k]);
                        }
                    }
                }
            }
        });

        dropdownObserver.observe(document.body, { childList: true, subtree: true });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            window.initCustomDropdowns();
            hookJQueryVal();
            observeDynamicSelects();
        });
    } else {
        window.initCustomDropdowns();
        hookJQueryVal();
        observeDynamicSelects();
    }
})();
