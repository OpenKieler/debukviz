package de.cau.cs.kieler.klighd.debug.transformations

import de.cau.cs.kieler.core.kgraph.KNode
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
import de.cau.cs.kieler.core.krendering.extensions.KLabelExtensions
import de.cau.cs.kieler.kiml.options.EdgeLabelPlacement

class KeyValueTransformation extends AbstractDebugTransformation {
   
    @Inject
    extension KNodeExtensions
    @Inject
    extension KRenderingExtensions
    @Inject 
    extension KPolylineExtensions
    @Inject 
    extension KLabelExtensions 
    
    override transform(IVariable model) {
        return KimlUtil::createInitializedNode() => [
            it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.kiml.ogdf.planarization")
            it.addLayoutParam(LayoutOptions::SPACING, 50f)
            it.addLayoutParam(LayoutOptions::LAYOUT_HIERARCHY, true)
            it.addLayoutParam(LayoutOptions::DEBUG_MODE, true)
            it.addLayoutParam(LayoutOptions::DIRECTION, Direction::RIGHT)
            model.getVariables("table").filter[variable | variable.valueIsNotNull].forEach[
                IVariable variable | 
                    it.createKeyValueNode(variable)
                    val next = variable.getVariable("next");
                    if (next.valueIsNotNull)
                        it.createKeyValueNode(next)
            ]
        ]
    }
    
    def createKeyValueNode(KNode node, IVariable variable) {
       	val key = variable.getVariable("key")
       	val value = variable.getVariable("value")
	   	/*node.children += key.createNodeById() => [
	       	it.addLabel("Key:")
	       	it.nextTransformation(key)
	   	]
	   	node.children += value.createNodeById() => [
	       	it.addLabel("Value:")
	       	it.nextTransformation(value)
	   	]*/
	   	node.addNewNodeById(key) => [
	       	it.nextTransformation(key)
	   	]
	   	node.addNewNodeById(value) => [
	    	it.nextTransformation(value)
	   	]
        key.createEdgeById(value) => [
            value.createLabel(it) => [
                it.addLayoutParam(LayoutOptions::EDGE_LABEL_PLACEMENT,EdgeLabelPlacement::CENTER)
                it.text = "value";
            ]
            it.data += renderingFactory.createKPolyline() => [
                it.setLineWidth(2);
                it.addArrowDecorator();
            ]
        ]
    }
}