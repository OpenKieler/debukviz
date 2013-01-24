package de.cau.cs.kieler.klighd.debug.transformations

import de.cau.cs.kieler.core.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KPolylineExtensions
import de.cau.cs.kieler.core.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.kiml.options.Direction
import de.cau.cs.kieler.kiml.options.LayoutOptions
import de.cau.cs.kieler.kiml.util.KimlUtil
import de.cau.cs.kieler.klighd.debug.visualization.AbstractDebugTransformation
import javax.inject.Inject
import org.eclipse.debug.core.model.IVariable

import static de.cau.cs.kieler.klighd.debug.visualization.AbstractDebugTransformation.*

class ArrayDequeTransformation extends AbstractDebugTransformation {
    
    @Inject
    extension KNodeExtensions 
    @Inject 
    extension KPolylineExtensions 
    @Inject
    extension KRenderingExtensions
    
    var IVariable previous = null
    
    override transform(IVariable model) {
        return KimlUtil::createInitializedNode() => [
            it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.klay.layered")
            it.addLayoutParam(LayoutOptions::SPACING, 75f)
            it.addLayoutParam(LayoutOptions::DIRECTION, Direction::RIGHT);
            val head = Integer::parseInt(model.getValue("head"));
            val tail = Integer::parseInt(model.getValue("tail"));
            val IVariable[] elements = model.getVariables("elements");
            var int index = head;
            while (index <= tail) {
                val variable = elements.get(index)
                val node = it.nextTransformation(variable)
                if (index == head)
                	node.addLabel("head")
                if (index == tail-1)
                	node.addLabel("tail")
                if (previous != null)
                    previous.createEdgeById(variable) => [
                        it.data += renderingFactory.createKPolyline() => [
                            it.setLineWidth(2)
                            it.addArrowDecorator();
                        ]
                    ]
                previous = variable
                index = index + 1
            }
        ]
    }
    
}