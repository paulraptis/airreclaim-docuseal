const MIN_SCALE = 1
const MAX_SCALE = 2
const STEP = 0.25

export default class extends HTMLElement {
  connectedCallback () {
    this.viewport = this.querySelector('[data-document-zoom-viewport]')
    this.canvas = this.querySelector('[data-document-zoom-canvas]')
    this.output = this.querySelector('[data-document-zoom-output]')
    this.scale = MIN_SCALE
    this.pinch = null

    this.onClick = this.onClick.bind(this)
    this.onTouchStart = this.onTouchStart.bind(this)
    this.onTouchMove = this.onTouchMove.bind(this)
    this.onTouchEnd = this.onTouchEnd.bind(this)

    this.addEventListener('click', this.onClick)
    this.viewport?.addEventListener('touchstart', this.onTouchStart, { passive: true })
    this.viewport?.addEventListener('touchmove', this.onTouchMove, { passive: false })
    this.viewport?.addEventListener('touchend', this.onTouchEnd, { passive: true })
    this.viewport?.addEventListener('touchcancel', this.onTouchEnd, { passive: true })
    this.render()
  }

  disconnectedCallback () {
    this.removeEventListener('click', this.onClick)
    this.viewport?.removeEventListener('touchstart', this.onTouchStart)
    this.viewport?.removeEventListener('touchmove', this.onTouchMove)
    this.viewport?.removeEventListener('touchend', this.onTouchEnd)
    this.viewport?.removeEventListener('touchcancel', this.onTouchEnd)
  }

  onClick (event) {
    const button = event.target.closest('[data-document-zoom-action]')
    if (!button || !this.contains(button)) return

    const action = button.dataset.documentZoomAction
    if (action === 'in') this.setScale(this.scale + STEP)
    if (action === 'out') this.setScale(this.scale - STEP)
    if (action === 'reset') this.setScale(MIN_SCALE)
  }

  onTouchStart (event) {
    if (event.touches.length !== 2) return
    this.pinch = {
      distance: touchDistance(event.touches),
      scale: this.scale
    }
  }

  onTouchMove (event) {
    if (!this.pinch || event.touches.length !== 2) return
    event.preventDefault()
    const ratio = touchDistance(event.touches) / Math.max(1, this.pinch.distance)
    this.setScale(this.pinch.scale * ratio)
  }

  onTouchEnd (event) {
    if (event.touches.length < 2) this.pinch = null
  }

  setScale (nextScale) {
    const previousScale = this.scale
    this.scale = Math.min(MAX_SCALE, Math.max(MIN_SCALE, Math.round(nextScale * 100) / 100))
    if (previousScale === this.scale) return

    const viewportCenter = (this.viewport?.scrollLeft || 0) + ((this.viewport?.clientWidth || 0) / 2)
    this.render()

    if (this.viewport && previousScale > 0) {
      const scaledCenter = viewportCenter * (this.scale / previousScale)
      this.viewport.scrollLeft = Math.max(0, scaledCenter - (this.viewport.clientWidth / 2))
    }
  }

  render () {
    if (!this.canvas) return
    this.canvas.style.width = `${this.scale * 100}%`
    this.viewport?.classList.toggle('is-enlarged', this.scale > MIN_SCALE)

    const percent = `${Math.round(this.scale * 100)}%`
    if (this.output) this.output.textContent = percent
    this.querySelector('[data-document-zoom-action="out"]')?.toggleAttribute('disabled', this.scale <= MIN_SCALE)
    this.querySelector('[data-document-zoom-action="in"]')?.toggleAttribute('disabled', this.scale >= MAX_SCALE)
  }
}

function touchDistance (touches) {
  return Math.hypot(touches[1].clientX - touches[0].clientX, touches[1].clientY - touches[0].clientY)
}
